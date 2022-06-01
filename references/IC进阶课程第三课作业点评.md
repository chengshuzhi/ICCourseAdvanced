

## 一、 课程内容回顾



### 1. Canister 数据结构

![image-20220528104353291](/Users/suzy/Library/Application Support/typora-user-images/image-20220528104353291.png)



```
1. 正交持久化： orthogonal Persistence， 程序本身不需要关注数据是如何存储的。 
2. 方法调用成功完成，被修改的状态会自动持久化。
3. Heap内存再升级canister代码时会被清空，而stable 内存则永久保留。
4. Stable 内存不仅仅用于升级，随时可以用。
```



### 2. 升级canister 代码

![image-20220601211414981](/Users/suzy/Library/Application Support/typora-user-images/image-20220601211414981.png)

```
1. pre-upgrade ： 完全stopped 状态 升级才比较安全。运行pre-upgrade是旧代码。
2. post- upgarde ： 运行post-upgrade的是新代码。
3. 期间发生任何错误，则升级中断回滚。
4. 在升级的过程中（stopped期间）被另外一个canister 调用， 发送方会收到错误消息。
```

### 3. 在Motoko 中使用 Stable Var

```
1. 声明为stable 的变量，会直接被保存，可以在升级后使用。
2. 升级之前的类型，应该是升级之后类型的子类型。
3. 升级的过程， 在类型中增加了新的字段，升级之前的类型就不满足是升级之后的类型了。
4. 如果在记录结构中添加新字段，添加的是Option类型是可以的，因为可以缺省值是null。

```

### 4. 概念对比  stable shared

<img src="/Users/suzy/Library/Application Support/typora-user-images/image-20220601212900137.png" alt="image-20220601212900137" style="zoom:80%;" />

```
1. 数据的改变只能通过canister 内部进行，不能通过共享数据。
2. shared类型，不包含本地的私有方法，和 可变数据类型mutable类型。
3. stable 相对于shared，可以包含mutable字段的类型。因为升级前后还在同一个canister里。
```

### 5. 在消息传递中发送Cycles

![image-20220601213348437](/Users/suzy/Library/Application Support/typora-user-images/image-20220601213348437.png)

## 二、 作业讲解

![image-20220601214250612](/Users/suzy/Library/Application Support/typora-user-images/image-20220601214250612.png)



```
参考链接：

1.  actor class 参数初始化： M N 小组成员 （N可有可无）
2. 	create canister 每个人都可以创建 ，不需要添加权限限制。
3. 	在调用 IC Management Canister 的时候，给出足够的 cycle。
4.  类型定义
		public type CanisterInfo = {
        canister_id: Principal;
        is_restricted: Bool;
    };

    public type OperationType = {
        #install;
        #start;
        #stop;
        #delete;
        #addRestricted;
        #removeRestricted;
    };

    public type Proposal = {
        proposal_id : Nat;
        proposal_maker : Principal;
        operation_type : OperationType;
        canister_id : Principal;
        wasm_module : ?Wasm_module;
        proposal_approve_num : Nat;
        proposal_approvers : [Principal];
        proposal_refuse_num : Nat;
        proposal_refusers: [Principal];
        proposal_completed: Bool;
    };
    
5. 业务定义
// 1. 创建canister，记录这个多人钱包所创建的所有canister id
    stable var canisters: Trie.Trie<Principal, Types.CanisterInfo> = 			Trie.empty<Principal, Types.CanisterInfo>();
    
    // 1. create canister 
    public shared ({caller}) func create_canister() : async ?Principal{
        assert (checkMember(caller));
        let settings = {
            freezing_threshold = null;
            controllers = ?[Principal.fromActor(self)];
            memory_allocation = null;
            compute_allocation = null;
        };

        let ic : IC.Self =  actor("aaaaa-aa");
        let create_result  = await ic.create_canister({settings = ? settings});
        //add canister to canisters
        canisters := Trie.put(
            canisters, 
            {hash = Principal.hash(create_result.canister_id); key = create_result.canister_id}, 
            Principal.equal, 
            {canister_id = create_result.canister_id; is_restricted = false}
        ).0;
        return ?create_result.canister_id;
    };
    
// 2. 提出提案
    stable var proposals : Trie.Trie<Nat, Types.Proposal> = Trie.empty<Nat, Types.Proposal>();
    
    // -- 1. 增加限制 addRestricted  
    //      首选校验canister的状态是没有限制的。 如果有限制直接返回，如果无限制，把提案放入提案列表。
    // -- 2. 删除限制 removeRestricted  stop/start/install/delete
    //        首选校验 canister 的状态是限制的。如果没有限制，则表示不需要经过提案。
    
        //2. make a proposal
    public shared ({caller})  func  make_proposal (operation_type: Types.OperationType, canister_id : Principal, wasm_module: ?Types.Wasm_module) : async () {
            //1. check caller is one of members
            assert (checkMember(caller));
            //2.  check canister exist
            assert (checkCanisterExist(canister_id));
            
            //3. check canister restricted or not
            switch (operation_type) {
                //3.1 add Restricted, check canister not restricted
                case (#addRestricted) { assert(not checkRestricted(canister_id)) };
                //3.2 remove Restricted/start stop install delete, check canister restricted
                case (_) { assert( checkRestricted(canister_id)); };
            };
            //4. add to proposals
            pushProposal(caller, operation_type, canister_id, wasm_module);
    };
    
    
    private func pushProposal (caller: Principal, operation_type: Types.OperationType, canister_id: Principal, wasm_module: ?Types.Wasm_module) {
        proposalId += 1;
        proposals :=  Trie.put (proposals, {hash = Hash.hash(proposalId); key =  proposalId}, Nat.equal, {
            proposal_id = proposalId;
            proposal_maker  = caller;
            operation_type = operation_type;
            canister_id = canister_id;
            wasm_module = wasm_module;
            proposal_approve_num = 0;
            proposal_approvers = [];
            proposal_refuse_num = 0;
            proposal_refusers = [];
            proposal_completed = false;
        }).0;
    };
  
// 3. 投票 && 自动执行
    //3. vote for proposal
    public shared ({caller}) func vote_proposal (proposal_id: Nat, approve: Bool) : async () {
        switch (Trie.get(proposals, {hash = Hash.hash(proposal_id); key = proposal_id}, Nat.equal)) {
            case (?proposal){
                var proposal_approvers = proposal.proposal_approvers;
                var proposal_approve_num = proposal.proposal_approve_num;
                var proposal_refusers = proposal.proposal_refusers;
                var proposal_refuse_num = proposal.proposal_refuse_num;
                if(approve){
                    proposal_approvers := Array.append([caller], proposal_approvers);
                    proposal_approve_num += 1;
                } else {
                    proposal_refusers := Array.append([caller], proposal_refusers);
                    proposal_refuse_num += 1;
                };
                let new_proposal = {
                    proposal_id = proposal.proposal_id;
                    proposal_maker  = proposal.proposal_maker;
                    operation_type = proposal.operation_type;
                    canister_id = proposal.canister_id;
                    wasm_module = proposal.wasm_module;
                    proposal_approve_num = proposal_approve_num;
                    proposal_approvers = proposal_approvers;
                    proposal_refuse_num = proposal_refuse_num;
                    proposal_refusers = proposal_refusers;
                    proposal_completed = false;
                };

                proposals := Trie.replace(proposals, {hash = Hash.hash(proposal_id); key =  proposal_id}, Nat.equal, ?new_proposal).0;

                if (proposal_approve_num >= threshold and (not proposal.proposal_completed)) {
                    // auto execute proposal
                    await execute_proposal(new_proposal);

                };

            };
            case (_) { };
        }
    };

    //4. execute proposal
    private func execute_proposal (proposal : Types.Proposal) : async () {
        switch (proposal.operation_type) {
            case (#addRestricted) {
                add_restricted(proposal.canister_id);
            };
            case (#removeRestricted) {
                remove_restricted(proposal.canister_id);
            };
            case (#start) {
                await start_canister(proposal.canister_id);
            };
            case (#stop) {
                await stop_canister(proposal.canister_id);
            };
            case (#install) {
                await install_code(proposal.canister_id, proposal.wasm_module);
            };
            case (#delete) {
                await delete_canister(proposal.canister_id);
            };
        };

        let new_proposal = {
            proposal_id = proposal.proposal_id;
            proposal_maker  = proposal.proposal_maker;
            operation_type = proposal.operation_type;
            canister_id = proposal.canister_id;
            wasm_module = proposal.wasm_module;
            proposal_approve_num = proposal.proposal_approve_num;
            proposal_approvers = proposal.proposal_approvers;
            proposal_refuse_num = proposal.proposal_refuse_num;
            proposal_refusers = proposal.proposal_refusers;
            proposal_completed = true;
        };
        proposals := Trie.replace(proposals, {hash = Hash.hash(proposal.proposal_id); key =  proposal.proposal_id}, Nat.equal, ?new_proposal).0;

    };
```




