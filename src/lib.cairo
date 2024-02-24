// #[starknet::interface]
// trait IHelloStarknet<TContractState> {
//     fn increase_balance(ref self: TContractState, amount: felt252);
//     fn get_balance(self: @TContractState) -> felt252;
// }

// #[starknet::contract]
// mod HelloStarknet {
//     #[storage]
//     struct Storage {
//         balance: felt252, 
//     }

//     #[abi(embed_v0)]
//     impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
//         fn increase_balance(ref self: ContractState, amount: felt252) {
//             assert(amount != 0, 'Amount cannot be 0');
//             self.balance.write(self.balance.read() + amount);
//         }

//         fn get_balance(self: @ContractState) -> felt252 {
//             self.balance.read()
//         }
//     }
// }

mod ERC404;


// mod mtk;

// use starknet::ContractAddress;
// #[starknet::interface]
// trait IListExample<TContractState> {
//     fn add_in_amount(ref self: TContractState, number: u256);
//     fn add_in_task(ref self: TContractState, description: felt252, status: felt252);
//     fn is_empty_list(self: @TContractState) -> bool;
//     fn list_length(self: @TContractState) -> u32;
//     fn get_from_index(self: @TContractState, index: u32) -> u256;
//     fn set_from_index(ref self: TContractState, index: u32, number: u256);
//     fn pop_front_list(ref self: TContractState);
//     fn array_conversion(self: @TContractState) -> Array<u256>;

//     fn set_owned(ref self: TContractState, owner: ContractAddress, id: u256);
// }

// #[starknet::contract]
// mod ListExample {
//     use alexandria_storage::list::{List, ListTrait};

//     use starknet::ContractAddress;

//     #[storage]
//     struct Storage {
//         amount: List<u256>,
//         tasks: List<Task>,
//         owned: LegacyMap<ContractAddress, List<u256>>,
//     }

//     #[derive(Copy, Drop, Serde, starknet::Store)]
//     struct Task {
//         description: felt252,
//         status: felt252
//     }

//     #[abi(embed_v0)]
//     impl ListExample of super::IListExample<ContractState> {
//         fn set_owned(ref self: ContractState, owner: ContractAddress, id: u256) {
//             let mut owned_list = self.owned.read(owner);
//             owned_list.append(id);
//         }

//         fn add_in_amount(ref self: ContractState, number: u256) {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.append(number);
//         }

//         fn add_in_task(ref self: ContractState, description: felt252, status: felt252) {
//             let new_task = Task { description: description, status: status };
//             let mut current_tasks_list = self.tasks.read();
//             current_tasks_list.append(new_task);
//         }

//         fn is_empty_list(self: @ContractState) -> bool {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.is_empty()
//         }

//         fn list_length(self: @ContractState) -> u32 {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.len()
//         }

//         fn get_from_index(self: @ContractState, index: u32) -> u256 {
//             self.amount.read()[index]
//         }

//         fn set_from_index(ref self: ContractState, index: u32, number: u256) {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.set(index, number);
//         }

//         fn pop_front_list(ref self: ContractState) {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.pop_front();
//         }

//         fn array_conversion(self: @ContractState) -> Array<u256> {
//             let mut current_amount_list = self.amount.read();
//             current_amount_list.array().unwrap()
//         }
//     }
// }


