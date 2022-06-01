
import IC "./ic";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Time "mo:base/Time";

actor class () = self {

    type CanisterInfo = { id : Principal; name : Text; time : ?Time.Time};

    stable var canister_info : ?CanisterInfo = null; 

    // stable var canister_id : ?IC.canister_id = null;

    // system func postupgrade () {
    //     canister_info := Option.map( canister_id,
    //         func (id: Principal) : CanisterInfo {
    //             {id = id ; name = "(none)" }
    //          })
    // };
    
    public func create_canister() : async IC.canister_id {
        let settings = {
            freezing_threshold = null;
            controllers = ?[Principal.fromActor(self)];
            memory_allocation = null;
            compute_allocation = null;
        };

        let ic : IC.Self = actor("aaaaa-aa");

        let result = await ic.create_canister({ settings = ?settings; });

        canister_info := ? {id = result.canister_id; name = "(none)"; time = ?Time.now()};

        result.canister_id;
    };

    public func get_canister_info() : async ?CanisterInfo {
        canister_info
    };

};
