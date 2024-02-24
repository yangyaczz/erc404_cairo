// // use starknet::ContractAddress;

// // use snforge_std::{declare, ContractClassTrait};

// // use erc404_cairo::IHelloStarknetSafeDispatcher;
// // use erc404_cairo::IHelloStarknetSafeDispatcherTrait;
// // use erc404_cairo::IHelloStarknetDispatcher;
// // use erc404_cairo::IHelloStarknetDispatcherTrait;

// // fn deploy_contract(name: felt252) -> ContractAddress {
// //     let contract = declare(name);
// //     contract.deploy(@ArrayTrait::new()).unwrap()
// // }

// // #[test]
// // fn test_increase_balance() {
// //     let contract_address = deploy_contract('HelloStarknet');

// //     let dispatcher = IHelloStarknetDispatcher { contract_address };

// //     let balance_before = dispatcher.get_balance();
// //     assert(balance_before == 0, 'Invalid balance');

// //     dispatcher.increase_balance(42);

// //     let balance_after = dispatcher.get_balance();
// //     assert(balance_after == 42, 'Invalid balance');
// // }

// // #[test]
// // fn test_cannot_increase_balance_with_zero_value() {
// //     let contract_address = deploy_contract('HelloStarknet');

// //     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

// //     #[feature("safe_dispatcher")]
// //     let balance_before = safe_dispatcher.get_balance().unwrap();
// //     assert(balance_before == 0, 'Invalid balance');

// //     #[feature("safe_dispatcher")]
// //     match safe_dispatcher.increase_balance(0) {
// //         Result::Ok(_) => panic_with_felt252('Should have panicked'),
// //         Result::Err(panic_data) => {
// //             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
// //         }
// //     };
// // }

// use erc404_cairo::IListExampleDispatcher;
// use erc404_cairo::IListExampleDispatcherTrait;


// use starknet::ContractAddress;
// use starknet::contract_address_const;


// use snforge_std::{declare, ContractClassTrait, start_prank, CheatTarget};
// use snforge_std::errors::{SyscallResultStringErrorTrait, PanicDataOrString};

// use traits::TryInto;

// use core::serde::Serde;


// fn deploy_contract(name: felt252) -> ContractAddress {
//     let contract = declare(name);

//     contract.deploy(@ArrayTrait::new()).unwrap()
// }


// #[test]
// // #[should_panic(expected: ('ERC721: invalid token ID', ))]
// fn test_transfer() {
//     let erc404_address = deploy_contract('ListExample');
//     let erc404 = IListExampleDispatcher { contract_address: erc404_address };

//     erc404.add_in_amount(10.try_into().unwrap());
//     erc404.add_in_amount(30.try_into().unwrap());
//     erc404.add_in_amount(40.try_into().unwrap());

//     println!("get from ifex {}", erc404.get_from_index(0));
//     println!("get from ifex {}", erc404.get_from_index(1));
//     println!("get from ifex {}", erc404.get_from_index(2));
//     println!("len {}",erc404.list_length());
//     erc404.pop_front_list();

//     println!("len {}",erc404.list_length());
//     println!("get from ifex {}", erc404.get_from_index(0));
//     println!("get from ifex {}", erc404.get_from_index(1));
//     // println!("get from ifex {}", erc404.get_from_index(2));
// }

