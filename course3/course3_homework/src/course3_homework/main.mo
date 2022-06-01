
import Principal "mo:base/Principal";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Option "mo:base/Option";

import IC "./ic";
import Types "./types";

// 1. 创建canister，记录这个多人钱包所创建的所有canister id

// 2. 提出提案
    // -- 1. 增加限制 addRestricted  
    //      首选校验 canister 的状态是没有限制的。 如果有限制直接返回，如果没有限制，把提案放入提案列表。
    // -- 2. 删除限制 removeRestricted  stop/start/install/delete
    //        首选校验 canister 的状态是限制的。如果没有限制，则表示不需要经过提案。
  
// 3. 投票 && 自动执行

// 4. 创建canister 传送 cycles 



actor class (threshold : Nat, total : Nat, members : [Principal]) = self {

    //canisters
    stable var canisters: Trie.Trie<Principal, Types.CanisterInfo> = Trie.empty<Principal, Types.CanisterInfo>();
    // members
    stable var memberSet : TrieSet.Set<Principal> = TrieSet.fromArray<Principal>(members, Principal.hash, Principal.equal);
    // proposals
    stable var proposals : Trie.Trie<Nat, Types.Proposal> = Trie.empty<Nat, Types.Proposal>();

    stable var proposalId : Nat = 0 ;

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

    private func checkMember(member: Principal) : Bool {
        TrieSet.mem(memberSet, member, Principal.hash(member), Principal.equal);
    };

    private func checkCanisterExist(canister_id: Principal) : Bool {
        switch (Trie.get(canisters, {hash = Principal.hash(canister_id); key =  canister_id}, Principal.equal)) {
            case null return false;
            case _ return true;
        };
    };

    private func checkRestricted (canister_id : Principal) : Bool {
        switch(Trie.get(canisters, {hash = Principal.hash(canister_id); key = canister_id}, Principal.equal)) {
            case (?canister_info) return canister_info.is_restricted;
            case null return false;

        };
    };


    // delete canister 
    private func delete_canister(canister_id : Principal) : async () {
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.delete_canister({canister_id = canister_id});
    };

    // stop canister
    private func stop_canister(canister_id : Principal) : async () {
        let ic: IC.Self = actor("aaaaa-aa");
        let result = await ic.stop_canister ({ canister_id = canister_id});
    };

    // start canister
    private func start_canister(canister_id : Principal) : async () {
        let ic: IC.Self = actor("aaaaa-aa");
        let result = await ic.start_canister ({ canister_id = canister_id});
    };

    // install code
    private func install_code(canister_id : Principal, wasm_module : ?Types.Wasm_module) : async () {

        let ic : IC.Self =  actor("aaaaa-aa");
        await ic.install_code ({
            arg = [];
            wasm_module = Option.unwrap(wasm_module);
            mode = #install;
            canister_id = canister_id;
        });
       
    };

    private func add_restricted(canister_id : Principal) : () {
        let new_canister_info : Types.CanisterInfo = {
            canister_id = canister_id;
            is_restricted = true;
        };
        canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key =  canister_id}, Principal.equal, ?new_canister_info).0;
    };

    private func remove_restricted(canister_id : Principal) : () {
        let new_canister_info : Types.CanisterInfo = {
            canister_id = canister_id;
            is_restricted = false;
        };
        canisters := Trie.replace(canisters, {hash = Principal.hash(canister_id); key =  canister_id}, Principal.equal, ?new_canister_info).0;
    };

};