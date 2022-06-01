export const idlFactory = ({ IDL }) => {
  const canister_id = IDL.Principal;
  const anon_class_5_1 = IDL.Service({
    'create_canister' : IDL.Func([], [canister_id], []),
  });
  return anon_class_5_1;
};
export const init = ({ IDL }) => { return []; };
