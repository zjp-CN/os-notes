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
    duration: f32,
    complete: bool,
    waker: Option<Waker>,
}

pub struct TimerFuture {
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
            println!("Ready: Timer for {} secs", shared_state.duration);
            Poll::Ready(())
        } else {
            println!("Pending: Timer for {} secs", shared_state.duration);
            // set a waker which wakes up the task on completion
            shared_state.waker = Some(cx.waker().clone());
            Poll::Pending
        }
    }
}

impl TimerFuture {
    pub fn new(secs: f32) -> Self {
        let state = Arc::new(Mutex::new(SharedState {
            duration: secs,
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
                println!("Completed for {secs} sec");
            }
        });
        TimerFuture { state }
    }
}

pub struct Executor {
    receiver: Receiver<Arc<MyWaker>>,
}

impl Executor {
    fn new(receiver: Receiver<Arc<MyWaker>>) -> Self {
        Executor { receiver }
    }

    fn run(&self) {
        let mut i = 0;
        // exit when senders are all droped
        while let Ok(my_waker) = self.receiver.recv() {
            let waker = Waker::from(my_waker.clone());
            let cx = &mut Context::from_waker(&waker);
            match my_waker.task.lock().unwrap().as_mut().poll(cx) {
                Poll::Ready(_) => println!("[{i}] Done"),
                Poll::Pending => println!("[{i}] Pending"),
            };
            i += 1;
        }
    }

    pub fn block_on<Fut: 'static + Send + Future<Output = ()>>(
        f: impl FnOnce(Arc<Spawner>) -> Fut,
    ) {
        let (sender, receiver) = channel();
        let spawner = Arc::new(Spawner::new(sender));

        spawner.spawn(f(spawner.clone()));

        // decrement a sender count to wake up receive side
        drop(spawner);

        Executor::new(receiver).run();
    }
}

pub struct Spawner {
    sender: Sender<Arc<MyWaker>>,
}

impl Spawner {
    fn new(sender: Sender<Arc<MyWaker>>) -> Self {
        Spawner { sender }
    }

    pub fn spawn(&self, fut: impl 'static + Send + Future<Output = ()>) {
        let my_waker = Arc::new(MyWaker {
            task: Mutex::new(Box::pin(fut)),
            sender: self.sender.clone(),
        });
        self.sender.send(my_waker).unwrap();
    }

    pub fn spawn_result(&self, fut: impl 'static + Send + Future<Output = crate::Result<()>>) {
        let my_waker = Arc::new(MyWaker {
            task: Mutex::new(Box::pin(async {
                if let Err(err) = fut.await {
                    eprintln!("Future returns an error:\n{err}");
                }
            })),
            sender: self.sender.clone(),
        });
        self.sender.send(my_waker).unwrap();
    }
}
