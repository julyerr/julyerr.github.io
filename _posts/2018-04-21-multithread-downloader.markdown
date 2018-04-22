---
layout:     post
title:      "多线程下载器"
subtitle:   "多线程下载器"
date:       2018-04-21 6:00:00
author:     "julyerr"
header-img: "img/projects/filedownloader/filedownloader.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - concurrent
---

>后台开发人员，多线程、网络、数据库等原生编程能力决定了你的高度；以前阅读过这方面的很多书籍，但是实践的经验相对缺少一点，这一阵子打算好好弥补一下。<br>

github上的开源项目很多，阅读高手代码，改进，变成自己的工具，个人认为是提高实践经验较好的途径。<br>

今天就一个多线程文件下载[工具](https://github.com/daimajia/java-multithread-downloader.git)进行分析，该工程代码量不大（大概1200行左右），实现多线程下载文件的功能，同时支持断点续传的功能。<br>

下面是整个项目的workflow

![](/img/projects/filedownloader/workflow.png)

#### 多线程下载文件工作原理
将整个文件划分为不同段（通常通过设置"Content-Range"请求头实现），然后各个线程下载好对应的资源，通过拼接的方式恢复出原始文件。<br>

**断点续传**是指如果下载任务取消或者失败，将已经下载好和未下载完毕的位置保存下来，下次恢复下载的时候，从该位置开始下载即可。


----
篇幅原因，只对整体运行流程和关键结构、代码进行分析，所有代码[参见](https://github.com/julyerr/webutils/tree/master/java-multithread-downloader)

### DownloadManager

一个下载的文件，对应一个下载任务(DownloadMission),DownloadManager对所有下载任务进行管理，包括添加、删除、暂停以及一些状态信息等。<br>

#### 重要成员变量及方法

![](/img/projects/filedownloader/missionM.png)
![](/img/projects/filedownloader/missionM2.png)

**线程池**

```java
private static DownloadThreadPool mThreadPool = new DownloadThreadPool(DEFAULT_CORE_POOL_SIZE,
                DEFAULT_MAX_POOL_SIZE, DEFAULT_KEEP_ALIVE_TIME,
                TimeUnit.SECONDS, new LinkedBlockingDeque<Runnable>());
```

**下载任务集合**

```java
private Hashtable<Integer, DownloadMission> mMissions = new Hashtable<Integer, DownloadMission>();
```


### DownloadThreadPool

继承自ThreadPoolExecutor，重写了submit、afterExecute方法

#### 重要成员变量

![](/img/projects/filedownloader/threadpool.png)


```java
//每个mission_id，对应一个队列，队列中存储同一个mission的多个线程运行之后的结果
private ConcurrentHashMap<Integer, ConcurrentLinkedQueue<Future<?>>> mMissions_Monitor = new ConcurrentHashMap<>();

//设置该结构主要是方便操作已经完成的任务，对于future.isDone()可以从该队列中移除
private ConcurrentHashMap<Future<?>, Runnable> mRunnable_Monitor_HashMap = new ConcurrentHashMap<>();
```


#### 重要方法

**任务提交**

```java
public Future<?> submit(Runnable task) {
//      提交任务，先运行
    Future<?> future = super.submit(task);
    if (task instanceof DownloadRunnable) {
        DownloadRunnable runnable = (DownloadRunnable) task;

        if (mMissions_Monitor.containsKey(runnable.MISSION_ID)) {
//          结果添加到 mMissions_Monitor 队列中
            mMissions_Monitor.get(runnable.MISSION_ID).add(future);
        } else {
//                构建新的任务队列
            ConcurrentLinkedQueue<Future<?>> queue = new ConcurrentLinkedQueue<>();
            queue.add(future);
            mMissions_Monitor.put(runnable.MISSION_ID, queue);
        }

        mRunnable_Monitor_HashMap.put(future, task);

    } else {
        throw new RuntimeException(
                "runnable is not an instance of DownloadRunnable!");
    }
    return future;
}
```

**afterExecute**

```java
protected void afterExecute(Runnable r, Throwable t) {
    super.afterExecute(r, t);
    if (t == null) {
        System.out.println(Thread.currentThread().getId()
                + " has been succeesfully finished!");
    } else {
        System.out.println(Thread.currentThread().getId()
                + " errroed! Retry");
    }
    for (Future<?> future : mRunnable_Monitor_HashMap.keySet()) {
        //    如果有新的线程完成，开启新的线程继续分担下载任务
        if (future.isDone() == false) {
            DownloadRunnable runnable = (DownloadRunnable) mRunnable_Monitor_HashMap
                    .get(future);
            DownloadRunnable newRunnable = runnable.split();
            if (newRunnable != null) {
//                    只新建一个线程
                submit(newRunnable);
                break;
            }
        }
    }
}
```

**cancel**

```java
public void cancel(int mission_id) {
    ConcurrentLinkedQueue<Future<?>> futures = mMissions_Monitor
            .remove(mission_id);
    for (Future<?> future : futures) {
//            移除，取消
        mRunnable_Monitor_HashMap.remove(future);
        future.cancel(true);
    }
}
```


### DownloadRunnable

所有的成员变量和方法

![](/img/projects/filedownloader/downloadrunnable.png)


#### 重要方法

**run**

```java
public void run() {
    File targetFile;
//          建立目录
    File dir = new File(mSaveDirectory + File.pathSeparator);
    if (dir.exists() == false) {
        dir.mkdirs();
    }
//          创建文件
    targetFile = new File(mSaveDirectory + File.separator
            + mSaveFileName);
    if (targetFile.exists() == false) {
        try {
            targetFile.createNewFile();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    System.out.println("Download Task ID:" + Thread.currentThread().getId()
            + " has been started! Range From " + mCurrentPosition + " To "
            + mEndPosition);
    BufferedInputStream bufferedInputStream = null;
    RandomAccessFile randomAccessFile = null;
    byte[] buf = new byte[BUFFER_SIZE];
    URLConnection urlConnection = null;
    if (mStartPosition < mEndPosition) {
        try {
            try {
                //            打开URL连接，设置读取数据段
                URL url = new URL(mFileUrl);
                urlConnection = url.openConnection();
                urlConnection.setRequestProperty("Range", "bytes="
                        + mCurrentPosition + "-" + mEndPosition);
                randomAccessFile = new RandomAccessFile(targetFile, "rw");
//            设置当下位置
                randomAccessFile.seek(mCurrentPosition);
//               以前版本的一个bug，需要建立好连接才能获取到输出和输出流
                urlConnection.connect();
                this.inputStream = urlConnection.getInputStream();
                bufferedInputStream = new BufferedInputStream(
                        urlConnection.getInputStream());
                while (mCurrentPosition < mEndPosition) {
//                如果发生了中断，退出
                    if (Thread.currentThread().isInterrupted()) {
                        System.out.println("Download TaskID:"
                                + Thread.currentThread().getId()
                                + " was interrupted, Start:" + mStartPosition
                                + " Current:" + mCurrentPosition + " End:"
                                + mEndPosition);
                        break;
                    }
                    int len = bufferedInputStream.read(buf, 0, BUFFER_SIZE);
                    if (len == -1)
                        break;
                    else {
                        randomAccessFile.write(buf, 0, len);
                        mCurrentPosition += len;
                        mDownloadMonitor.down(len);
                    }
                }
            } finally {
                bufferedInputStream.close();
                randomAccessFile.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

**split**

```java
public DownloadRunnable split() {
    int end = mEndPosition;
    int remaining = mEndPosition - mCurrentPosition;
    int remainingCenter = remaining / 2;
    System.out.print("CurrentPosition:" + mCurrentPosition
            + " EndPosition:" + mEndPosition + "Rmaining:" + remaining
            + " ");
//        1024×1024
    if (remainingCenter > 1048576) {
        int centerPosition = remainingCenter + mCurrentPosition;
        System.out.print(" Center position:" + centerPosition);
        //    将任务分段,多线程直接操作mEndPosition是有风险的，但是下载速度很慢，mEndPosition变化在BUF_SIZE(远小于1M)，发生错误很小很小
        mEndPosition = centerPosition;

        DownloadRunnable newSplitedRunnable = new DownloadRunnable(
                mDownloadMonitor, mFileUrl, mSaveDirectory, mSaveFileName,
                centerPosition + 1, end);
        mDownloadMonitor.mHostMission.addPartedMission(newSplitedRunnable);
        return newSplitedRunnable;
    } else {
        System.out.println(toString() + " can not be splited ,less than 1M");
        return null;
    }
}
```

**interrupt**

为了及时停止文件的下载过程，提供interrupt()方法（future.cancel会自动调用）

```java
try {
    //引发数据读取异常，然后退出while循环
    this.inputStream.close();
    } catch (IOException e) {
    }
}
```

### DownloadMission

成员变量和方法相对多一点

#### 重要成员变量

```java
//    传入的线程池引用
protected DownloadThreadPool mThreadPoolRef;
//    任务启动的线程数组
private ArrayList<DownloadRunnable> mDownloadParts = new ArrayList<>();
//    恢复任务数组
private ArrayList<RecoveryRunnableInfo> mRecoveryRunnableInfos = new ArrayList<>();

```

**内部类**<br>

**RecoveryRunnableInfo**

![](/img/projects/filedownloader/recoveryRunnable.png)

保存从文件中恢复过来的下载信息，用于重新进行下载。


**SpeedMonitor**

监控下载速度信息，通过mSpeedTimer定时器定时更新

```java

mSpeedTimer.scheduleAtFixedRate(mSpeedMonitor, 0, 1000);

private static class SpeedMonitor extends TimerTask {
    //...
    @Override
    //      每一秒时间更新速度
    public void run() {
        mCounter++;
        mCurrentSecondSize = mHostMission.getDownloadedSize();
        mSpeed = mCurrentSecondSize - mLastSecondSize;
        mLastSecondSize = mCurrentSecondSize;
        if (mSpeed > mMaxSpeed) {
            mMaxSpeed = mSpeed;
        }

        mAverageSpeed = mCurrentSecondSize / mCounter;
    }
}

```

**StoreMonitor**

将一个下载任务信息保存到xml文件中，使用javax.xml.bind.annotation.*注解某个类以及相关的成员变量，可以实现将类实例保存到文件中和从文件中加载这个类实例

```java
//保存
JAXBContext context = JAXBContext
        .newInstance(DownloadMission.class);
Marshaller m = context.createMarshaller();
m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
m.marshal(this, getProgressFile());

//加载
JAXBContext context = JAXBContext
        .newInstance(DownloadMission.class);
Unmarshaller unmarshaller = context.createUnmarshaller();
DownloadMission mission = (DownloadMission) unmarshaller
        .unmarshal(progressFile);
```

同样，此类通过mStoreTimer定时器定时将实例信息保存到文件中

```java
//每5秒将实例信息保存到文件中
mStoreTimer.scheduleAtFixedRate(mStoreMonitor, 0, 5000);

private class StoreMonitor extends TimerTask {
    @Override
    public void run() {
//          每5秒更新文件内容
        storeProgress();
    }
}
```

**MissionMonitor**

保存所有线程下载字节数，同时在下载完成时，将任务取消。

```java
//多线程可能同时进行操作
private AtomicInteger mDownloadedSize = new AtomicInteger();

public void down(int size) {
    mDownloadedSize.addAndGet(size);
    if (mDownloadedSize.intValue() == mHostMission.getFileSize()) {
        mHostMission.setDownloadStatus(FINISHED);
    }
}

public int getDownloadedSize() {
    return mDownloadedSize.get();
}
```

#### 重要方法

**newDownloadMission**

静态方法，新建一个任务，如果任务完成，返回null

```java
public static DownloadMission newDownloadMission(String url, String saveDirectory, String saveName)
        throws IOException {
//        如果任务已经下载完成，返回
    if (isMission_Finished(url, saveDirectory, saveName)) {
        return null;
    }

    DownloadMission downloadMission = new DownloadMission(url, saveDirectory, saveName);
    return downloadMission;
}

public static boolean isMission_Finished(String url, String saveDirectory, String saveName)
            throws IOException {
    int size = getContentLength(url);
    if (saveDirectory.endsWith("/")) {
        saveDirectory = saveDirectory.substring(0, saveDirectory.length() - 1);
    }
    File file = new File(saveDirectory + "/" + saveName);
//        下载文件大小和网络请求所获文件大小相同
    if (file.length() == size) {
        return true;
    }
    return false;
}
```

**resumeMission**

```java
//    将xml文件内容恢复到对象中
private void resumeMission() throws IOException {

    try {
        File progressFile = new File(FileUtils.getSafeDirPath(mProgressDir)
                + File.separator + mProgressFileName);
        if (progressFile.exists() == false) {
            throw new IOException("Progress File does not exsist");
        }

        JAXBContext context = JAXBContext
                .newInstance(DownloadMission.class);
        Unmarshaller unmarshaller = context.createUnmarshaller();
        DownloadMission mission = (DownloadMission) unmarshaller
                .unmarshal(progressFile);
        File targetSaveFile = new File(
                FileUtils.getSafeDirPath(mission.mSaveDirectory
                        + File.separator + mission.mSaveName));
        if (targetSaveFile.exists() == false) {
            throw new IOException(
                    "Try to continue download file , but target file does not exist");
        }
//            将下载信息放入到recoveryRunnableInfo数组中
        ArrayList<RecoveryRunnableInfo> recoveryRunnableInfos = getDownloadProgress();
        recoveryRunnableInfos.clear();
        for (DownloadRunnable runnable : mission.mDownloadParts) {
            recoveryRunnableInfos.add(new RecoveryRunnableInfo(runnable
                    .getStartPosition(), runnable.getCurrentPosition(),
                    runnable.getEndPosition()));
        }
        mSpeedMonitor = new SpeedMonitor(this);
        mStoreMonitor = new StoreMonitor();
        System.out.println("Resume finished");
        mDownloadParts.clear();
    } catch (JAXBException e) {
//            e.printStackTrace();
    }
}
```

**splitDownload**

```java
//    将整个文件平均分给每个线程
private ArrayList<DownloadRunnable> splitDownload(int thread_count) {
    ArrayList<DownloadRunnable> runnables = new ArrayList<DownloadRunnable>();
    try {
        int size = getContentLength(mUrl);
        mFileSize = size;
        int sublen = size / thread_count;
        for (int i = 0; i < thread_count; i++) {
            int startPos = sublen * i;
            int endPos = (i == thread_count - 1) ? size
                    : (sublen * (i + 1) - 1);
            DownloadRunnable runnable = new DownloadRunnable(this.mMonitor,
                    mUrl, mSaveDirectory, mSaveName, startPos, endPos);
            runnables.add(runnable);
        }
    } catch (IOException e) {
        e.printStackTrace();
    }
    return runnables;
}
```

**startMission**

```java
//    分为恢复和重新下载两个逻辑
public void startMission(DownloadThreadPool threadPool) {
    try {
        resumeMission();
    } catch (IOException e) {
        e.printStackTrace();
    }
    mThreadPoolRef = threadPool;
    if (mRecoveryRunnableInfos.size() != 0) {
//            将恢复结果中未下载完毕的文件下载完毕
        for (RecoveryRunnableInfo runnableInfo : mRecoveryRunnableInfos) {
            if (runnableInfo.isFinished == false) {
                setDownloadStatus(DOWNLOADING);
                DownloadRunnable runnable = new DownloadRunnable(mMonitor,
                        mUrl, mSaveDirectory, mSaveName,
                        runnableInfo.getStartPosition(),
                        runnableInfo.getCurrentPosition(),
                        runnableInfo.getEndPosition());
                mDownloadParts.add(runnable);
                threadPool.submit(runnable);
            }
        }
    } else {
//            重新下载
        setDownloadStatus(DOWNLOADING);
        for (DownloadRunnable runnable : splitDownload(mThreadCount)) {
            mDownloadParts.add(runnable);
            threadPool.submit(runnable);
        }
    }
//        利于垃圾回收
    mRecoveryRunnableInfos = null;
    mSpeedTimer.scheduleAtFixedRate(mSpeedMonitor, 0, 1000);
    mStoreTimer.scheduleAtFixedRate(mStoreMonitor, 0, 5000);
}
```

**任务下载完成或者被取消**

```java
private void setDownloadStatus(int status) {
//        先设置好状态，然后保存到xml
    mMissionStatus = status;
    if (status == FINISHED) {
//            可以取消该任务
        cancel();
    }
}

public void cancel() {
    mSpeedTimer.cancel();
    mStoreMonitor.cancel();
    mDownloadParts.clear();
    mThreadPoolRef.cancel(mMissionID);
    deleteProgressFile();
}
```

#### 可以简单写一个demo进行测试

```java
public static void main(String[] args) {
    DownloadManager downloadManager = DownloadManager.getInstance();
    String qQString = "http://down.myapp.com/android/45592/881859/qq2013_4.0.2.1550_android.apk";

    /*** type you save direcotry ****/
    String saveDirectory = "/home/julyerr/Desktop";
    try {
        DownloadMission mission = newDownloadMission(qQString,
                saveDirectory, "test1");
        downloadManager.addMission(mission);
        downloadManager.start();
        int counter = 0;
        while (true) {
            System.out.println("Downloader information Speed:"
                    + downloadManager.getReadableTotalSpeed()
                    + " Down Size:"
                    + downloadManager.getReadableDownloadSize());
            Thread.sleep(1000);
            counter++;
        }
    } catch (IOException e1) {
        e1.printStackTrace();
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
}
```

---
### 参考资料
- [java-multithread-downloader](https://github.com/daimajia/java-multithread-downloader/)