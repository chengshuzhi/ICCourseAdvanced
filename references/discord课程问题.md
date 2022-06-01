```
1. 启动报错，不知名错误
dfx stop
dfx start --clean 

2. 课程问题
可以看一下学生手册哈。

3. 如何找回cycles wallet？
dfx identity get-principal 
test.icscan.io 看principal下控制的canister 应该包含wallet。
dfx identity get-wallet

4. 如何使用motoko代码 创建 canister
可以参考这个 https://qiuyedx.com/?p=865 

需要注意的是，class 和 actor class 是完全两回事。一般能够 import 的都是 class，你可以去看看 motoko-base, vessel-package-set 里面的的库。根据 class new 出来的是对象，在canister 程序里面。actor class new 出来的是不同 actor，也就是新生成 canister。一般需要 await


5. deploy项目的时候，会报错，需要去git仓库下载vessel package，一般是网络问题。
https://github.com/dfinity/vessel/issues/39

6. case 取出的类型是 ？Bucket， 不是 Bucket。 -- 模式匹配

7.icp的nft标注 提供mixLabs的。

8. 调用ExperimentalCycles 报错
我用的 0.9.3，更新到 0.10.0 有问题，就没升级了 Error: Invalid data: unable to gunzip file: Unexpected GZIP ID: value=[60, 63], expected=[31, 139]

不要升级 0.10.0
这个问题好像和域名解析有关系，目前还没搞清楚


9. view 方法不能是query类型，因为需要跨canister 调用。

如果在 query 方法里掉其他 canister 的方法好像会报错。应该让 query 之间可以互调的，但因为可能跨子网的原因，如果有跨 canister 调用，就需要走一下共识。

10. List 类型的iterate 函数里的入参函数不能是异步函数。

11. 还需要再 import Hash "mo:base/Hash";

12. 不知道如何下手
你应该卡在那个 Logger 上面，你可以在看完老师的视频之后，一步一步来，比如先实现只能存 100条记录的 Logger，这个就是新建一个数据结构，比如List或者数组之类的来存，然后实现两个接口。这步完成后就可以考虑怎么在 canister 创建canister 并触发等。



13. 命令行如何传入枚举值
参考文章 https://qiuyedx.com/?p=886
variant { ok = 42 }
variant { "unicode, too: ☃" = true }
variant { fall }

dfx canister call testMeiju greet '(variant {Web = "Shuzhi"})'

14. dfx canister install 的时候会生成wasm文件
路径在 ./../../.dfx/local/canisters/XXX/XXX.wasm
```



