助教手册： https://forested-celsius-818.notion.site/IC-1-2c138a42873142b993ccf97bc3002658

## 一、第一课 Motoko进阶语言

1. Motoko Canister 容器
 Actor： 对外有一套公共的接口。用户可以直接调用。 
    Canister 之间的通信，以及用户和Canister之前的通信 都是异步的。 
    await ： 执行了await之后，本次请求已经发送出去，本次请求就已经完成了，响应是另外的一个反向请求。
    call back： 方法。 响应时调用call back。
    所有的请求必须有响应，所以当回调栈不为空时，是不能停止该canister的。

 Module： 编译器不允许module里有stable 变量。因为两个actor可以调用同一个module， 那么通过调用module就可以实现对可变状态变量的修改了。 但是在motoko中，这是不被允许的，两个actor 需要通过请求进行通信。 

 ```

 库模块： Array、 Result
 本地模块： types、 utils
 Actor Class： 

import Counters "Counters"; // 这里引入的Counters 是actor class

actor CountToTen {
   let c: Counters. Counter = await Counters. Counter(1);
   ……
}

创建actor（新的canister） 是有系统开销的，所以是需要await 异步调用的。 

Canister

import BigMap "canister: BigMap"
import Connected "canister: Connected"


 ```

Object 和 Class

```
Object 是一个记录结构

Class Counter() {
	var c = 0 ;
	public func inc() : Nat {
		c+= 1;
		return c;
	}
};

let c1 = Counter();
let c2 = Counter();
let x = c1.inc();
其中，c1.c 和c2.c 的状态是不同的。 并且class里的变量c 是private 的，需要通过public 的方法进行调用。

Class Counter(init:Nat)  {
	var c = init;
	public func inc() : Nat { c += 1;  c;}
};
let c1 = Counter(0);
let c2 = Counter(10);
```



Buffer

```
Buffer: 可变长度的序列

import Buffer "mo:Base/Buffer";

Class Counter<X> (init Buffer.Buffer<X>) {
	var buffer = init.clone();
	public func add(x :X) Nat {buffer.add(x); buffer.size()};
	public func reset() {buffer := init.clone()};
};

let c1 = Counter(Buffer.Buffer<Int>(10));
let c2 = Counter<Nat>(Buffer.Buffer(10));

Buffer 类型在base库里的定义：
public class Buffer<X> (initCapacity : Nat) {
 ...
};

HashMap 类型在base库里的定义：
public class HashMap<K,V> (
	initCapacity : Nat,
	keyeq : <K, K> -> Bool,
	KeyHash : K -> Hash.Hash ) {
	...
};

```



Actor Class 

```
Class 是为了创建某一个类型的Object
Actor Class 是为了创建某一个类型的Actor
实现的方法是公用的，但是具体的状态是分开的。 

actor class 里的公共方法必须是异步的。

import Nat "mo:Base/Nat";
import Nat "mo:Base/RBTree";

actor class Bucket(n:Nat, i:Nat) {
	type Key = Nat;
	type value = Text;
	
	let map = Map.RBTree<Key,Value>(Nat.compare);
	
	public func get (k: key) : async ?Value {
		assert((k%n) == i);
    map.get(k);
	};
	
	public func put (k : Key, v : Value) : async() {
		assert ((k%n) == i);
		map,put(k,v);
	};
};


import Array "mo:Base/Array";
import Buckets "Buckets";

actor Map {
	let n= 8; //number of buckets
	
	type Key = Nat;
	type Value = Text;
	
	type Bucket = Buckets.Bucket;
	
	let buckets : [var ?Bucket] = Array.init(n,null); // n:size
	
	public func get(k : Key) : async ?Value {
		switch (buckets[k%n]){
			case null null;
			case (?bucket) await bucket.get(k);
		};
	};
	
	public func put(k : Key, v : Value) : async () {
		let i = k % n ;
		let bucket = switch (buckets[i]) {
			case null {
				let b = await Buckets.Bucket(n,i);//dynamically install a new Bucket
				buckets[i] = ?b;
				b;
			};
			case (?bucket) bucket;
		};
		await bucket.put(k,v);
	};
};

```

子类型subtype

```
子类型关系 subtype
B<= A. B是A的子类型
所有接受A类型值的地方都可以使用B类型

Nat 是int 的子集

```

使用Vessel管理程序库

```
https://github.com/dfinity/vessel

import "mo:sha256/SHA256";

```

使用matchers 进行单元测试

```

```

Logger演示

```
wget https://github.com/dfinity/vessel/releases/download/v0.6.3/vessel-macos // 下载安装包

chmod a+x vessel-macos // 修改权限为可执行

mv vessel-macos ~/bin/vessel // 移动安装环境

which vessel

which dfx

dfx canister call logger stats 

dfx canister call logger append '( vec {"first entry"})'

// 所有新的canister/actor 都是通过钱包安装的，所以它的owner 是钱包地址。
// 普通的调用是用的自己的principal id。 

 dfx canister --wallet $(dfx identity get-wallet) call logger allow "( vec {principal \"$(dfx identity get-principal)\"})"
 
 dfx canister call logger append '(vec {"second entry"})'
 
 dfx cansiter call logger view '(0,100)'
 dfx canister call logger view '(0,0)'
 
 //在命令行通过vessel安装使用的包
 $(dfx cache show)/moc $(vessel sources) -r Logger.mo
 
```

课程作业

```
1. 子类型
false
true
false
true
false

false
true
true
false
false

2. 实现一个可以无限扩容的logger
stable memory 是放在主内存里的 -- heap memory。

mkdir homework1
vessel init

修改 package-set.dhall
let additions = [
      { name = "ic-logger"
      , repo = "https://github.com/ninegua/ic-logger"
      , version = "95e06542158fc750be828081b57834062aa83357"
      , dependencies = [ "base" ]
      }
    ]
    
    
修改 vessel.dhall

{
  dependencies = [ "base", "matchers", "ic-logger" ],
  compiler = None Text
}

修改dfx.json 设置
"defaults": {
    "build": {
      "args": "",
      "packtool": "vessel sources"
    }
  }
 
 
 oneway??
 
 



```



## 第二课 Canister 开发进阶

canister 与系统之间的关系

```
mo文件 被编译器 编译成 .wasm 文件，然后在IC 上执行。

系统对Canister 的调用
canister_init 
canister_pre_upgrade： 把heap memory 里的数据存储到 stable memory。
如果pre_upgrade失败，则升级失败。
canister_post_upgrade: 继承了之前的memory，根据stable memory的情况，初始化一些状态。

inspect_message: query call  打包的时候对消息进行检查。 还没有经过共识。目前在motoko里还没有支持，Rust是支持的。

0.9.2 实现了heartbert： 谨慎使用 ？？

回调函数： 发出请求时指定在接收响应时使用哪个回调函数。

Canister 对系统的调用

以太坊是完全公开的计算，没有任何秘密。
chainkey： 分布式签名。
能够让节点联合在一起，各自签名然后聚合。 

IC Management Canister: 
所提供的方法都是需要异步调用的。 
这个cansiter 不存在webassembly的概念。

IC的特性： 得到的签名是不可预测的。 超过阈值聚合出的签名一定是相同的。 
无论如何产生的，产生的值是相同的，并且是不受控制的。 

以上三个类型的调用。

```



Candid接口规范

```
1. candid 的主要目的是为了描述一个服务。 
	可以描述更多的数据类型，包括函数类型，递归类型。 
	函数类型可以描述服务接口和方法。 
	升级过程中的类型适配。
	
2. 多语言支持：
	Javascript Motoko Rust
	Python Go Haskell AssemblyScript
	
```



IC 双向消息传递的保证 bi- directional messaging

```
但凡发出的消息，必须先收到回答： 升级的时候，需要先stop 再upgrade。
每个消息最多被处理一次： 没有被处理的，会返回错误给发送方。

异步的调用才会抛出异常。

Motoko try/catch 仅用于对异步的异常处理

非异步的异常，是不会被捕获的： 消息的发送方会收到异常，但是调用异常的函数不会收到异常。

常见错误： 调用await的时候，有可能其他方法被调用，修改到公用的balance值。

```



Candid 工具演示

```
https://github.com/dfinity/candid

https://github.com/dfinity/candid/releases/download/2022-03-30/didc-macos
curl -LO https://github.com/dfinity/candid/releases/download/2022-03-30/didc-macos
chmod a+x didc-macos
./didc-macos --help

https://github.com/dfinity/interface-spec

curl -LO https://raw.githubusercontent.com/dfinity/interface-spec/master/spec/ic.did

mv didc-macos /usr/local/bin/didc
didc bind --help
didc bind -t mo ic.did
didc bind -t mo ic.did > ic.mo

第二课待办；
1. 写作业的几个方法
2. 使用repl


```



## 第三课

```
1. 正交持久化： orthogonal Persistence， 程序本身不需要关注数据是如何存储的。 
方法调用成功完成，被修改的状态会自动持久化。

Heap内存再升级canister代码时会被清空，而stable 内存则永久保留。

数据结构：
```

![image-20220528104353291](/Users/suzy/Library/Application Support/typora-user-images/image-20220528104353291.png)



升级canister 代码

```
created -- running -- stopping -- stopped

pre-upgrade ： 完全stopped 状态 升级才比较安全。运行pre-upgrade是旧代码。
install new code
canister init
post- upgarde ： 运行post-upgrade的是新代码。

在升级的过程中被另外一个canister 调用， 发送方会收到错误消息。

```

在Motoko 中使用 Stable Var

```
声明为stable 的变量，会直接被保存，可以在升级后使用。
升级之前的类型，应该是升级之后类型的子类型。

升级的过程， 在类型中增加了新的字段，升级之前的类型就不满足是升级之后的类型了。
如果在记录结构中添加新字段，添加的是Option类型是可以的，因为可以缺省值是null。

```

概念对比。stable shared

```
数据的改变只能通过canister 内部进行，不能通过共享数据。
shared类型，不包含mutable类型。可变数据类型，mutable ， 不能传给另外一个actor。

stable 相对于shared，可以包含mutable字段的类型。因为升级前后还在同一个canister里。

```

canister 使用Cycles的场景

```
canister 为自己付费：
1. 从cycle 余额中支付： update call 和storage
2. 以发消息的方式支付（跨canister 通信，调用 IC Management Canister）

```



The IC management canister address is `aaaaa-aa` (i.e. the empty blob).













1. github 
2.  canister 架构
3. canister controller 升级 权限 -- 力全 陈岩
4. notion
5. 飞书 计划 
6. 近期工作点：审计问题修改、新的canister部署
7. gallery、支持 icp交易
8. 

