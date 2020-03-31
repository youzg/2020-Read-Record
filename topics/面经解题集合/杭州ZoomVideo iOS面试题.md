# 杭州ZoomVideo iOS面试题

> 面经出自 [CSDN 博客](https://blog.csdn.net/weixin_33910460/article/details/91395190)

[TOC]

### 1. ARC和MRC了解多少，区别是什么，ARC和MRC各自有什么优缺点，ARC的引用计数的实现机制

ARC 是 LLVM 和 Runtime 协作的结果，ARC 中禁止调用 retain/release/retainCount/dealloc方法，新增weak strong。MRC 是手动管理内存。

简单地说，就是代码中自动加入了retain/release，原先需要手动添加的用来处理内存管理的引用计数的代码可以自动地由编译器完成了。ARC并不是GC，它只是一种代码静态分析（Static Analyzer）工具。比如如果不是 alloc/new/copy/mutableCopy 开头的函数，编译器会将生成的对象自动放入 autoreleasePool 中。如果是 __strong 修饰的变量，编译器会自动给其加上所有权。等等，详细，我们根据不同的关键字来看看编译器为我们具体做了什么。并从中总结出 ARC 的使用规则。

再深入的话就是引用计数 rc 底层实现，主要有两套，一个是全局的 sidetables，通过对象指针取到对应的 sidetable，结构体持有一个自旋锁，refcnt 表和 weaktables；另外一套对于 taggedpointer，nonponter-isa 存在高8位和19位，这个和架构有关。

MRC 使用可以参看 objective-c 基础知识点一文。

### 2. KVO了解么，实现机制是什么，KVO的addObserver方法如果传入的观察者是弱引用对象会怎么样？如果多次addObserver同一个观察者会怎么？如果多次remove同一个观察者会怎样？

KVO 会为需要observed的对象动态创建一个子类，以`NSKVONotifying_` 最为前缀，然后将对象的 isa 指针指向新的子类，同时重写 class 方法，返回原先类对象，这样外部就无感知了；其次重写所有要观察属性的setter方法，统一会走一个方法，然后内部是会调用 `willChangeValueForKey` 和 `didChangevlueForKey` 方法，在一个被观察属性发生改变之前， `willChangeValueForKey:`一定会被调用，这就 会记录旧的值。而当改变发生后，`didChangeValueForKey:`会被调用，继而 `observeValueForKey:ofObject:change:context:` 也会被调用。

![图片出处https://juejin.im/post/5adab70cf265da0b736d37a8](./res/kvo.png)

 objective-c 基础知识点一文有更详细的解答。

如果是弱引用对象会怎么样？`addObserver` 文档说明不会持有对象，且必须要手动移除。

> Neither the object receiving this message, nor `observer`, are retained. An object that calls this method must also eventually call either the [removeObserver:forKeyPath:](apple-reference-documentation://hc7WmoBbVT) or [removeObserver:forKeyPath:context:](apple-reference-documentation://hcAg3BWo_d) method to unregister the observer when participating in KVO.



1. 如果多次addObserver同一个观察者会怎么样？

   允许多次添加同一个观察者，即使观察的key是一样的，回调方法也会触发多次。

2. 如果多次remove同一个观察者会怎样？

   发生崩溃，抛出如下 Exception：

   ```shell
   Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <ViewController 0x7ff805c02d80> for the key path "name" from <Person 0x600001e7a300> because it is not registered as an observer.'
   ```

3. addObserver方法如果传入的观察者是弱引用对象会怎么样？

   由于是 weak 关键字指向，所以可能它指向的对象存在被释放的可能性，一旦被释放掉，那么之后如果触发了kvo事件，直接gg思密达。`EXEC_ BAD_ACCESS`野指针吧。

   > 测试了下 
   >
   > **@property**(**nonatomic**, **strong**)NSPointerArray *weakArray;
   >
   > **self**.weakArray = [NSPointerArray weakObjectsPointerArray];
   >
   > 如果 weak 对象置为nil后，那么持有指针也会变成 NULL。

### 3. 引用循环了解么，NSTimer使用时需要注意什么（1.引用循环；2.runloop；3.野指针。针对这三点进行描述）

[某智能物联网公司面试题.md#3循环引用如何避免](https://github.com/colourful987/2020-Read-Record/blob/master/topics/面经解题集合/某智能物联网公司面试题.md#3循环引用如何避免)，

野指针这个TODO。

### 4. block有了解多少，__block的实现原理

> 下面问题拷贝了对 block 用strong还是copy关键字解答。

block本身是像对象一样可以retain，和release。但是，block在创建的时候，它的内存是分配在栈上的，而不是在堆上。他本身的作于域是属于创建时候的作用域，一旦在创建时候的作用域外面调用block将导致程序崩溃。因为栈区的特点就是创建的对象随时可能被销毁,一旦被销毁后续再次调用空对象就可能会造成程序崩溃,在对block进行copy后，block存放在堆区.

retain strong copy 都是具有将栈上 block 赋值到堆上的操作，strong 和 copy 区别是前者会对堆上block对象引用计数+1。

通常声明 block 的作用域基本都是在栈上，如果只是作为函数传参变量，不持有它，在函数内部调用一次的话是没问题的，但是一旦函数作用域结束，你还想继续使用的话那么最好将block对象 copy 到堆上，建议最好声明为 copy。

Block 有三种类型：

* **NSMallocBlock** ：存放在堆区的 Block

* **NSStackBlock** ： 存放在栈区的 Block

* **NSGlobalBlock** ： 存放在全局区的 Block

Block 内部没有引用外部变量，Block 在全局区，属于 GlobalBlock；Block 引用了外部变量就是一个栈 Block，对于分配在栈区的对象，我们很容易会在释放之后继续调用（假设错用 assgin 或者 weak ），导致程序奔溃，所以我们使用的时候需要将栈区的对象移到堆区，来延长该对象的生命周期。

MRC： 使用 copy 修饰关键字来将栈上 block 复制到堆上；

ARC： 使用 strong 和 copy 效果同上；

`_block` 本身就是将变量搞成一个结构体封装，然后内部使用指针指向变量地址，然后将结构体传入到block中，修改值的时候是从这个结构体中取出来。

### 5. 一个controller有对应一些网络请求，如何在这个controller消失后，把对应的网络请求取消，请至少说出三种实现方式

方法一：

直接在页面消失或者  dealloc 的时候进行请求 cancel 操作。

方法二：：

1. 构建一个中间类A，该类在销毁执行dealloc时，顺便执行请求的cancel方法 
2. 通过associate绑定的方式，将销毁类绑定到任意执行类B上 
3. 这样，当执行类B销毁时，销毁内部的associate的属性时，我们就可以得到相应的执行时机。

方法三：

TODO：

### 6. NSArray数组越界会导致崩溃，如何屏蔽？屏蔽数组越界的崩溃有没有必要？

1. 方法交换掉对应的 objectAtIndex 方法，然后内部进行 try catch 操作；

在开发环境下不需要，线上可以借助 avoidcrash 第三方库进行预防。

### 7. YYModel实现原理

### 8. 三方库源码有了解多少

TODO，基本都会 AFNetworking SDWebImage 这种为主吧。

### 9. 一个UICollectionView从相册加载图片，在滑动的过程中会卡顿，请问如何优化？
