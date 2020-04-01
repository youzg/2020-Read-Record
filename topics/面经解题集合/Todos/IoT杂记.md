# 杂记，未整理的点

* [x] 崩溃收集的实现原理

  如何捕获：Mach 和 BSD 层的异常，前者就是起一个machserver， sigabrt 信号；后者就是平常说的 linux 信号，用signal函数注册6个信号，abrt/bus/fpe/ill/segv/trap；第三个就是nsuncaughtexceptionhandler。

  如何收集：暂停线程(`pthread_suspend()`)，抓线程堆栈信息，写文件和恢复线程，写文件使用 `open close write `等 unix 系统调用；`task_threads(mach_task_self(),&threads,&thread_count)` 读取线程数据，然后将app信息，手机硬件和操作系统等信息都写进去，写 Binary Images信息。单个线程的堆栈地址获取，是`plcrash_writer_write_thred()` 内部做的。`thread_get_state()` 拿寄存器状态。如果有额外的OC异常信息，也会把OC的异常信息写入到文件，之后还会写一下信号的信息到日志里，最后就是恢复所有线程让其继续执行，然后一些清理内存和端口的工作。原始崩溃日志的文件格式是protobuf，PLC有一个专门的格式化的类可以用来处理格式的转换，上传崩溃日志的时候用的上。

  另外protobuf格式的文件比json格式的文件压缩比要高，同一份文件protobuf格式比json格式的数据量要小，所以一些公司在TCP长连接的时候会采用这种格式来传输数据，消耗的流量更小一些，对弱网的支持会更好。

* [x] 为什么app在后台更加容易发生崩溃？代码层面如何避免此类崩溃

  iOS 后台保活有五种：

  1. Background Mode，地图，音乐播放，VoIP类应用；
  2. Background Fetch
  3. Silent Push，静默推送，后台唤起应用 30秒，会调起 `application:didReceiveRemoteNotifiacation`这个 delegate 和普通的 remote pushnotification 推送调用的delegate是一样的；
  4. PushKit，后台唤醒应用保活30秒，主要用于提升VoIP应用的体验；
  5. Background Task：后台执行任务；

  > 在程序退到后台后,只有几秒钟的时间可以执行代码,接下来会被系统挂起,进程挂起后所有的线程都会暂停,不管这个线程是文件读写还是内存读写都会被暂停,但是,数据读写过程无法暂停只能被中断,中断时数据读写异常而且容易损坏文件,所以系统会选择主动杀掉进程。更多请见[《如何全面监控线上iOS千奇百怪的崩溃》](https://www.jianshu.com/p/f63cf2c8d5c5)。

  Background Task 调用 `beginBackgroundTaskWithExpirationHandler` 方法将任务放置到后台执行：

  ```objective-c
  - (void)applicationDidEnterBackground:(UIApplication *)application {
      self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
          [self callTaskInBackground];
      }];
  }
  ```

  任务最多执行三分钟，三分钟后应用挂起，任务没完成就被系统强行杀掉进程，造成崩溃。

* [x] 崩溃率多少、大致是些什么崩溃

  >  更多请见：[iOS中的崩溃类型](https://www.jianshu.com/p/e1a3635ea30c)

  * EXC_BAD_ACCESS，野指针，开启 NSZombieEnabled 来排查；
  * SIGSEGV，当硬件出现错误、访问不可读的内存地址或向受保护的内存地址写入数据时，就会发生这个错误；SIGSEGV错误调试起来更困难，而导致SIGSEGV的最常见原因是不正确的类型转换。要避免过度使用指针或尝试手动修改指针来读取私有数据结构。如果你那样做了，而在修改指针时没有注意内存对齐和填充问题，就会收到SIGSEGV；
  * SIGBUS，总线错误信号（SIGBUG）代表无效内存访问，即访问的内存是一个无效的内存地址。也就是说，那个地址指向的位置根本不是物理内存地址（它可能是某个硬件芯片的地址）；
  * SIGTRAP，SIGTRAP代表陷阱信号。它并不是一个真正的崩溃信号。它会在处理器执行trap指令发送。LLDB调试器通常会处理此信号，并在指定的断点处停止运行。如果你收到了原因不明的SIGTRAP，先清除上次的输出，然后重新进行构建通常能解决这个问题；
  * EXC_ARITHMETIC，算术错误，除数不能为0；
  * SIGILL，SIGILL代表signal illegal instruction(非法指令信号)。当在处理器上执行非法指令时，它就会发生。执行非法指令是指，将函数指针会给另外一个函数时，该函数指针由于某种原因是坏的，指向了一段已经释放的内存或是一个数据段。有时你收到的是EXC_BAD_INSTRUCTION而不是SIGILL，虽然它们是一回事，不过EXC_*等同于此信号不依赖体系结构；
  * SIGABRT，代表SIGNAL ABORT（中止信号）。当操作系统发现不安全的情况时，它能够对这种情况进行更多的控制；必要的话，它能要求进程进行清理工作。在调试造成此信号的底层错误时，并没有什么妙招。Cocos2d或UIKit等框架通常会在特定的前提条件没有满足或一些糟糕的情况出现时调用C函数abort（由它来发送此信号）。当SIGABRT出现时，控制台通常会输出大量的信息，说明具体哪里出错了。由于它是可控制的崩溃，所以可以在LLDB控制台上键入bt命令打印出回溯信息；
  * SIGFPE: 浮点数错误
  * watchdog 超时

  ```json
  系统崩溃日志中异常出错的代码（常见代码有以下几种)
  0x8badf00d错误码：Watchdog超时，意为“ate bad food”。
  0xdeadfa11错误码：用户强制退出，意为“dead fall”。
  0xbaaaaaad错误码：用户按住Home键和音量键，获取当前内存状态，不代表崩溃。
  0xbad22222错误码：VoIP应用（因为太频繁？）被iOS干掉。
  0xc00010ff错误码：因为太烫了被干掉，意为“cool off”。
  0xdead10cc错误码：因为在后台时仍然占据系统资源（比如通讯录）被干掉，意为“dead lock”。
  ```

  

* [x] FPS 如何计算

  CADisplayLink，卡顿呢就是ping 或者 runloop 检测两个source之间 设置阈值.

* [x] runloop

* [x] arc 的理解

  ARC 是 LLVM 和 Runtime 协作的结果， ARC 中禁止调用retain/release/retainCount/dealloc方法，新增weak strong。而早期是采用 MRC ，手动管理内存。

  简单地说，就是代码中自动加入了retain/release，原先需要手动添加的用来处理内存管理的引用计数的代码可以自动地由编译器完成了。ARC并不是GC，它只是一种代码静态分析（Static Analyzer）工具。比如如果不是 alloc/new/copy/mutableCopy 开头的函数，编译器会将生成的对象自动放入 autoreleasePool 中。如果是 __strong 修饰的变量，编译器会自动给其加上所有权。等等，详细，我们根据不同的关键字来看看编译器为我们具体做了什么。并从中总结出 ARC 的使用规则。

* [x] 对象何时释放，结合runloop

  分几种情况去解释:

  1. 普通对象
  2. autorelease 对象，就算没有runloop 也是没有关系的， 有hotpage;

* [x] 如何检测循环引用

  1. instruments
  2. Xcode 自带的 retaincycle graph
  3. [FBRetainCycleDetector](https://github.com/facebook/FBRetainCycleDetector)，对象之间的引用关系的有向无环图（DAG 图）中寻找存在的环，为了更有效地进行对象筛选，Facebook开发了 FBAllocationTracker。这是一个用来主动追踪所有 NSObject 的子类的内存分配和释放操作的工具。它可以在最小的性能消耗下，在给定的时间点快速获取任何类的任何实例。

* [x] runtime 的应用

  1. 给分类添加属性

  2. 消息转发机制(NSProxy)

  3. 动态交换方法的实现

  4. 手动实现多继承（oc本身是不支持多继承的）

* [x] avoidcrash如何实现，如何处理崩溃

  [avoidcrash](https://github.com/chenfanfang/AvoidCrash) 的 README 文档，基本思想是方法交换，然后在 swizzled 方法中 `@try{}@catch{}`，然后在 catch 中获取堆栈信息。

* [ ] 原生与前端差异

* [ ] 前端的技术选型



* [x] 崩溃解析

  通常最简单的就是使用苹果提供的解析脚本 symbolicatecrash 进行崩溃解析，崩溃中都是地址符号，所以我们需要借助 dSYM 文件进行映射，将地址转成对应的符号，方便我们定位和排查问题，所以对于 UIKit 或者自己集成的第三方库只要你有 dSYM 文件也是可以解析出来的。

  ```shell
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  ./symbolicatecrash crash.log xxx.app.dSYM > result.log
  ```

  还有一种就是 `xcrun atos` 但是这个工作量大一些：

  ```shell
  xcrun atos -o AppName.app.dSYM/Contents/Resources/DWARF/AppName -l 0x1000d8000 0x000000010011a8b0 -arch arm64
  ```

  > 小知识：DWARF的全称是 ”Debugging With Attributed Record Formats“，遵从GNU FDL授权。现在已经有dwarf1，dwarf2，dwarf3三个版本。

* [x] 崩溃的类型

  见上

* [x] 前端与客户端区别

* [x] 弱网优化

  1. 合适的超时时间，针对不同网络设定不同的超时时间，加快超时，尽快重试
  2. 分子模块多请求去请求数据，避免一次性加载，导致数据太多请求返回慢；
  3. 缓存和增量请求
  4. **优化DNS查询：**应尽量减少DNS查询，做DNS缓存，避免域名劫持、DNS污染，同时把用户调度到“最优接入点”。
  5. 减小数据包大小和优化包量：通过压缩、精简包头、消息合并等方式，来减小数据包大小和包量。
  6. **优化ACK包：**平衡冗余包和ACK包个数，达到降低延时，提高吞吐量的目的。（这些难度有点高）
  7. 断线重连，因为我们是 socket 通信的，所以需要做断线重连，重连时间可以递增
  8. 减少数据连接的创建次数，由于创建连接是一个非常昂贵的操作，所以应尽量**减少数据连接的创建次数**，且在一次请求中应尽量以批量的方式执行任务。如果多次发送小数据包，应该尽量保证在2秒以内发送出去。在短时间内访问不同服务器时，尽可能地复用无线连接。
  9. 用户 UI 体验优化，加载一些动画什么的分散下注意力

* [ ] CI/CD

* [ ] 代码混淆

  预处理阶段对特定方法名进行字符替换

* [ ] 数据埋点，无痕埋点，遇到的问题
