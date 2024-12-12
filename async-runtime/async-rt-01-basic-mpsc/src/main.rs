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
    Executor { sender, receiver }.run(TimerFuture::new(2.0));
}

struct MyWaker {
    task: Mutex<Task>,
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

struct Task {
    fut: Pin<Box<dyn Send + Future<Output = ()>>>,
}

impl Future for Task {
    type Output = ();

    fn poll(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Self::Output> {
        self.fut.as_mut().poll(cx)
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
                thread::sleep(Duration::from_secs_f32(secs));
                let mut lock = state.lock().unwrap();
                lock.complete = true;
                lock.waker.as_mut().unwrap().wake_by_ref();
                println!("Completed");
            }
        });
        TimerFuture { state }
    }
}

struct Executor {
    receiver: Receiver<Arc<MyWaker>>,
    sender: Sender<Arc<MyWaker>>,
}

impl Executor {
    fn run(&self, fut: impl 'static + Send + Future<Output = ()>) {
        let my_waker = {
            let task = Task { fut: Box::pin(fut) };
            let my_waker = Arc::new(MyWaker {
                task: Mutex::new(task),
                sender: self.sender.clone(),
            });
            my_waker.sender.send(my_waker.clone()).unwrap();
            my_waker
        };
        let waker = Waker::from(my_waker);
        let cx = &mut Context::from_waker(&waker);
        while let Ok(w) = self.receiver.recv() {
            match w.task.lock().unwrap().fut.as_mut().poll(cx) {
                Poll::Ready(_) => {
                    println!("Done");
                    return;
                }
                Poll::Pending => eprintln!("Pending"),
            };
        }
    }
}
