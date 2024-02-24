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

