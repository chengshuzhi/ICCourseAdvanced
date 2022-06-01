export const idlFactory = ({ IDL }) => {
  const OperationType = IDL.Variant({
    'addRestricted' : IDL.Null,
    'stop' : IDL.Null,
    'removeRestricted' : IDL.Null,
    'delete' : IDL.Null,
    'start' : IDL.Null,
    'install' : IDL.Null,
  });
  const Wasm_module = IDL.Vec(IDL.Nat8);
  const anon_class_27_1 = IDL.Service({
    'create_canister' : IDL.Func([], [IDL.Opt(IDL.Principal)], []),
    'make_proposal' : IDL.Func(
        [OperationType, IDL.Principal, IDL.Opt(Wasm_module)],
        [],
        [],
      ),
    'vote_proposal' : IDL.Func([IDL.Nat, IDL.Bool], [], []),
  });
  return anon_class_27_1;
};
export const init = ({ IDL }) => {
  return [IDL.Nat, IDL.Nat, IDL.Vec(IDL.Principal)];
};
