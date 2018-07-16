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

>最近重温《多线程并发编程》一书，收获挺多的。一直想动手写一个多线程工具，本着不能盲目造轮子，参考了
许多大神在github上的多线程实现的各种玩意（[参考](https://github.com/daimajia/java-multithread-downloader.git)），最后决定做一个多线程的文件下载器。多线程文件下载器虽然
原理简单，但是把功能完善、各方面考虑周全还是有部分技术含量的。


下面是整个项目的workflow

![](/img/projects/filedownloader/workflow.png)

#### 多线程下载文件工作原理
将整个文件划分为不同段（通常通过设置"Content-Range"请求头实现），然后各个线程下载好对应的资源，通过拼接的方式恢复出原始文件。<br>

**断点续传**是指如果下载任务取消或者失败，将已经下载好和未下载完毕的位置保存下来，下次恢复下载的时候，从该位置开始下载即可。


----
篇幅原因，只对整体运行流程和关键结构、代码进行分析，所有代码[参见](https://github.com/julyerr/filedownloader)

### DownloadManager

一个下载的文件，对应一个下载任务(DownloadMission),DownloadManager对所有下载任务进行管理，包括添加、删除、暂停以及一些状态信息等。<br>

#### 重要成员变量及方法

![](/img/projects/filedownloader/missionM.png)

**线程池**

```java
private static DownloadThreadPool mThreadPool = new DownloadThreadPool(DEFAULT_CORE_POOL_SIZE,
                DEFAULT_MAX_POOL_SIZE, DEFAULT_KEEP_ALIVE_TIME,
                TimeUnit.SECONDS, new LinkedBlockingDeque<Runnable>());
```

**下载任务集合**

```java
//    防止多线程操作同一个DownLoadMission
private ConcurrentHashMap<Integer, DownloadMission> mMissions = new ConcurrentHashMap<>();
```

### DownloadThreadPool

继承自ThreadPoolExecutor，重写了submit、afterExecute方法

#### 重要成员变量

![](/img/projects/filedownloader/threadpool.png)


```java
//每个mission_id，对应一个队列，队列中存储同一个mission的多个线程运行之后的结果
private ConcurrentHashMap<Integer, ConcurrentLinkedQueue<Future<?>>> mMissionsMonitor = new ConcurrentHashMap<>();

//设置该结构主要是方便操作已经完成的任务，对于future.isDone()可以从该队列中移除
private ConcurrentHashMap<Future<?>, Runnable> mRunnableMonitor = new ConcurrentHashMap<>();
```


#### 重要方法

**任务提交**

```java
public Future<?> submit(Runnable task) {
//      提交任务，先运行
    Future<?> future = super.submit(task);
    if (task instanceof DownloadRunnable) {
        DownloadRunnable runnable = (DownloadRunnable) task;

        if (mMissionsMonitor.containsKey(runnable.MISSION_ID)) {
//          结果添加到 mMissionsMonitor 队列中
            mMissionsMonitor.get(runnable.MISSION_ID).add(future);
        } else {
//                构建新的任务队列
            ConcurrentLinkedQueue<Future<?>> queue = new ConcurrentLinkedQueue<>();
            queue.add(future);
            mMissionsMonitor.put(runnable.MISSION_ID, queue);
        }

        mRunnableMonitor.put(future, task);

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
//        自己忽略
    for (Future<?> future : mRunnableMonitor.keySet()) {
        //    如果有新的线程完成，开启新的线程继续分担下载任务
        if (future.isDone() == false) {
            DownloadRunnable runnable = (DownloadRunnable) mRunnableMonitor
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
    ConcurrentLinkedQueue<Future<?>> futures = mMissionsMonitor
            .remove(mission_id);
    if (futures == null) {
        return;
    }
    for (Future<?> future : futures) {
//            移除，取消
        Runnable runnable = mRunnableMonitor.remove(future);
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
//          创建文件
    targetFile = new File(mSaveDirectory + File.separator
            + mSaveFileName);

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
    long end = mEndPosition;
    long remaining = mEndPosition - mCurrentPosition;
    long remainingCenter = remaining >> 1;
    System.out.print("CurrentPosition:" + mCurrentPosition
            + " EndPosition:" + mEndPosition + "Rmaining:" + remaining
            + " ");
//        10*1024×1024
    if (remainingCenter > 10485760) {
        long centerPosition = remainingCenter + mCurrentPosition;
        System.out.print(" Center position:" + centerPosition);
        //    将任务分段,多线程直接操作mEndPosition是有风险的，但是下载速度很慢，mEndPosition变化在BUF_SIZE(远小于10M)，发生错误很小很小
        mEndPosition = centerPosition;

        DownloadRunnable newSplitedRunnable = new DownloadRunnable(
                mDownloadMonitor, mFileUrl, mSaveDirectory, mSaveFileName,
                centerPosition + 1, end);
        mDownloadMonitor.mHostMission.addPartedMission(newSplitedRunnable);
        return newSplitedRunnable;
    } else {
        System.out.println(toString() + " can not be splited ,less than 10M");
        return null;
    }
}
```

**interrupt**

为了及时停止文件的下载过程，提供interrupt()方法（future.cancel会自动调用）

```java
public void interrupt() {
    try {
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

//   每一秒时间更新速度
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
public static DownloadMission newDownloadMission(String url)
            throws IOException {
    File tmp = new File(".");
    String saveDirectory = tmp.getCanonicalPath();
    String saveName = url.substring(url.lastIndexOf("/") + 1);
    return newMissionInterface(url, saveDirectory, saveName);
}

private static DownloadMission newMissionInterface(String url, String saveDirectory, String saveName)
        throws IOException {
    //        如果任务已经下载完成，返回
    if (isMission_Finished(url, saveDirectory, saveName)) {
        return null;
    }
    createTargetFile(saveDirectory, saveName);
    createProgessFile(saveDirectory, saveName);

    return recoverMissionFromProgressFile(url, saveDirectory, saveName);
}
```

**recoverMissionFromProgressFile**

```java
public static DownloadMission recoverMissionFromProgressFile(
        String url, String dir, String name)
        throws IOException {
    DownloadMission mission = null;
    try {
        File progressFile = new File(
                FileUtils.getSafeDirPath(dir)
                        + File.separator + name + ".xml");

        JAXBContext context = JAXBContext
                .newInstance(DownloadMission.class);
        Unmarshaller unmarshaller = context.createUnmarshaller();
        mission = (DownloadMission) unmarshaller
                .unmarshal(progressFile);
        System.out.println("resume form file");
    } catch (JAXBException e) {
        mission = new DownloadMission();
    }
    mission.mUrl = url;
    mission.mSaveDirectory = dir;
    mission.mSaveName = name;
    mission.mProgressDir = dir;
    mission.mProgressFileName = name + ".xml";
//        unmarshall过程this无效
    mission.mSpeedMonitor.mHostMission = mission;
    mission.mMonitor.mHostMission = mission;
    mission.mMonitor.mDownloadedSize.set(0);
//            mission.mMissionID = MISSION_ID_COUNTER++;
    ArrayList<RecoveryRunnableInfo> recoveryRunnableInfos = mission
            .getDownloadProgress();
    for (DownloadRunnable runnable : mission.mDownloadParts) {
        mission.mRecoveryRunnableInfos.add(new RecoveryRunnableInfo(runnable
                .getStartPosition(), runnable.getCurrentPosition(),
                runnable.getEndPosition()));
    }
    mission.mDownloadParts.clear();
    return mission;
}
```

**splitDownload**

```java
 //    将整个文件平均分给每个线程
private ArrayList<DownloadRunnable> splitDownload(int thread_count) {
    ArrayList<DownloadRunnable> runnables = new ArrayList<>();
    try {
        long size = getContentLength(mUrl);
        mFileSize = size;
        long sublen = size / thread_count;
        for (int i = 0; i < thread_count; i++) {
            long startPos = sublen * i;
            long endPos = (i == thread_count - 1) ? size
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
    mThreadPoolRef = threadPool;
    if (mRecoveryRunnableInfos.size() != 0) {
//            将恢复结果剩余的未下载完毕的文件下载完毕
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
            mMonitor.mDownloadedSize.addAndGet(runnableInfo.mCurrentPosition - runnableInfo.mStartPosition);
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
    mStoreTimer.scheduleAtFixedRate(mStoreMonitor, 0, 1000);
}
```

**任务下载完成或者被取消**

```java
private void setDownloadStatus(int status) {
//        先设置好状态，然后保存到xml
    mMissionStatus = status;
    if (status == FINISHED) {
//            可以取消该任务
        mSpeedMonitor.mSpeed = 0;
        mSpeedTimer.cancel();
        mStoreMonitor.cancel();
        mDownloadParts.clear();
        deleteProgressFile();
        isFinished = true;
    }
}

public void cancel() {
//        速度置零
    mSpeedMonitor.mSpeed = 0;
    mSpeedTimer.cancel();
    mStoreMonitor.cancel();
    mDownloadParts.clear();
    mThreadPoolRef.cancel(mMissionID);
//  删除下载状态文件
    deleteProgressFile();
}
```

#### 可以简单写一个demo进行测试

```java
public static void main(String[] args) {
    DownloadManager downloadManager = DownloadManager.getInstance();
    String qQString = "https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-18.03.1.ce-1.el7.centos.x86_64.rpm";

    /*** type you save direcotry ****/
    String saveDirectory = "/home/julyerr/github/yourself/repo/filedownloader/target";
    try {
        DownloadMission mission = newDownloadMission(qQString,
                saveDirectory);
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
            if (downloadManager.isAllTasksFinished()) {
//                    让其他线程处理运行完成
                Thread.sleep(500);
                break;
            }
        }
    } catch (IOException e1) {
        e1.printStackTrace();
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    downloadManager.shutdDownloadRudely();
    System.exit(0);
}
```

---
### 参考资料
- [java-multithread-downloader](https://github.com/daimajia/java-multithread-downloader/)