import type { Principal } from '@dfinity/principal';
export type OperationType = { 'addRestricted' : null } |
  { 'stop' : null } |
  { 'removeRestricted' : null } |
  { 'delete' : null } |
  { 'start' : null } |
  { 'install' : null };
export type Wasm_module = Array<number>;
export interface anon_class_27_1 {
  'create_canister' : () => Promise<[] | [Principal]>,
  'make_proposal' : (
      arg_0: OperationType,
      arg_1: Principal,
      arg_2: [] | [Wasm_module],
    ) => Promise<undefined>,
  'vote_proposal' : (arg_0: bigint, arg_1: boolean) => Promise<undefined>,
}
export interface _SERVICE extends anon_class_27_1 {}
