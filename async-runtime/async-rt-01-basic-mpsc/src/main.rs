use std::{
    pin::Pin,
    sync::{
        Arc, Mutex,
        mpsc::{Receiver, Sender, channel},
    },
    task::{Context, Poll, Wake, Waker},
    thread,
    time::Duration,
};

fn main() {
    let (sender, receiver) = channel();
    let spawner = Spawner::new(sender);

    // spawn two tasks
    spawner.spawn(TimerFuture::new(2.0));
    spawner.spawn(TimerFuture::new(1.0));

    // decrement a sender count to wake up receive side
    drop(spawner);

    Executor::new(receiver).run();
}
// Pending
// Pending
// Sleep for 2 sec
// Sleep for 1 sec
// Completed for 1sec
// Done
// Completed for 2sec
// Done

struct MyWaker {
    task: Mutex<Pin<Box<dyn Send + Future<Output = ()>>>>,
    sender: Sender<Arc<Self>>,
}

impl Wake for MyWaker {
    fn wake(self: Arc<Self>) {
        self.wake_by_ref();
    }
    fn wake_by_ref(self: &Arc<Self>) {
        self.sender.send(self.clone()).unwrap();
    }
}

struct SharedState {
    complete: bool,
    waker: Option<Waker>,
}

struct TimerFuture {
    state: Arc<Mutex<SharedState>>,
}

impl Future for TimerFuture {
    type Output = ();

    fn poll(
        self: Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Self::Output> {
        let mut shared_state = self.state.lock().unwrap();
        if shared_state.complete {
            Poll::Ready(())
        } else {
            // set a waker which wakes up the task on completion
            shared_state.waker = Some(cx.waker().clone());
            Poll::Pending
        }
    }
}

impl TimerFuture {
    fn new(secs: f32) -> Self {
        let state = Arc::new(Mutex::new(SharedState {
            complete: false,
            waker: None,
        }));
        thread::spawn({
            let state = state.clone();
            move || {
                println!("Sleep for {secs} sec");
                thread::sleep(Duration::from_secs_f32(secs));
                let mut lock = state.lock().unwrap();
                lock.complete = true;

                // wake up the task by sending the future to executor
                lock.waker.take().unwrap().wake();
                println!("Completed for {secs}sec");
            }
        });
        TimerFuture { state }
    }
}

struct Executor {
    receiver: Receiver<Arc<MyWaker>>,
}

impl Executor {
    fn new(receiver: Receiver<Arc<MyWaker>>) -> Self {
        Executor { receiver }
    }

    fn run(&self) {
        // exit when senders are all droped
        while let Ok(my_waker) = self.receiver.recv() {
            let waker = Waker::from(my_waker.clone());
            let cx = &mut Context::from_waker(&waker);
            match my_waker.task.lock().unwrap().as_mut().poll(cx) {
                Poll::Ready(_) => println!("Done"),
                Poll::Pending => eprintln!("Pending"),
            };
        }
    }
}

struct Spawner {
    sender: Sender<Arc<MyWaker>>,
}

impl Spawner {
    fn new(sender: Sender<Arc<MyWaker>>) -> Self {
        Spawner { sender }
    }

    fn spawn(&self, fut: impl 'static + Send + Future<Output = ()>) {
        let my_waker = Arc::new(MyWaker {
            task: Mutex::new(Box::pin(fut)),
            sender: self.sender.clone(),
        });
        self.sender.send(my_waker).unwrap();
    }
}
