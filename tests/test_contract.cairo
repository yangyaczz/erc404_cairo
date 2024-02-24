// use starknet::ContractAddress;

// use snforge_std::{declare, ContractClassTrait};

// use erc404_cairo::IHelloStarknetSafeDispatcher;
// use erc404_cairo::IHelloStarknetSafeDispatcherTrait;
// use erc404_cairo::IHelloStarknetDispatcher;
// use erc404_cairo::IHelloStarknetDispatcherTrait;

// fn deploy_contract(name: felt252) -> ContractAddress {
//     let contract = declare(name);
//     contract.deploy(@ArrayTrait::new()).unwrap()
// }

// #[test]
// fn test_increase_balance() {
//     let contract_address = deploy_contract('HelloStarknet');

//     let dispatcher = IHelloStarknetDispatcher { contract_address };

//     let balance_before = dispatcher.get_balance();
//     assert(balance_before == 0, 'Invalid balance');

//     dispatcher.increase_balance(42);

//     let balance_after = dispatcher.get_balance();
//     assert(balance_after == 42, 'Invalid balance');
// }

// #[test]
// fn test_cannot_increase_balance_with_zero_value() {
//     let contract_address = deploy_contract('HelloStarknet');

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     #[feature("safe_dispatcher")]
//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     #[feature("safe_dispatcher")]
//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }

use erc404_cairo::ERC404::IERC404Dispatcher;
use erc404_cairo::ERC404::IERC404DispatcherTrait;


use starknet::ContractAddress;
use starknet::contract_address_const;


use snforge_std::{declare, ContractClassTrait, start_prank, CheatTarget};
use snforge_std::errors::{SyscallResultStringErrorTrait, PanicDataOrString};

use traits::TryInto;

use core::serde::Serde;

const NAME: felt252 = 'testtoken';
const SYMBOL: felt252 = 'tt';
const TOTALSUPPLY: u256 = 10_000_000_000_000_000_000_000;
const OWNER: felt252 = 'owner';


fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);

    // 1 solution
    // let mut calldata = array![NAME, SYMBOL];
    // let total_supply: u256 = TOTALSUPPLY;
    // total_supply.serialize(ref calldata);

    // 2 solution
    let mut call_data: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@NAME, ref call_data);
    Serde::serialize(@SYMBOL, ref call_data);
    Serde::serialize(@TOTALSUPPLY, ref call_data);
    Serde::serialize(@OWNER, ref call_data);

    // let contract_address = contract.precalculate_address(@call_data);
    // let owner = contract_address_const::<'owner'>();
    // start_prank(CheatTarget::One(contract_address), owner);

    contract.deploy(@call_data).unwrap()
}


#[test]
fn test_init() {
    let erc404_address = deploy_contract('ERC404');
    let erc404 = IERC404Dispatcher { contract_address: erc404_address };

    assert(erc404.name() == NAME, 'wrong name');
    assert(erc404.symbol() == SYMBOL, 'wrong symbol');
    assert(erc404.total_supply() == TOTALSUPPLY, 'wrong total supply');
    assert(erc404.balance_of(OWNER.try_into().unwrap()) == TOTALSUPPLY, 'wrong owner balance');
    assert(erc404.whitelist(OWNER.try_into().unwrap()), 'wrong whitelist');

    let mut i = 0;
    loop {
        if i == 10 {
            break();
        }
        println!("rarity {}", erc404.token_uri(i)[0]);
        println!("rarity {}", erc404.token_uri(i)[1]);
        println!("rarity {}", erc404.token_uri(i)[2]);
        println!("rarity {}", erc404.token_uri(i)[3]);
        println!("rarity {}", erc404.token_uri(i)[4]);
        println!("=================================");

        i = i+1;
    }
}

#[test]
#[ignore]
// #[should_panic(expected: ('ERC721: invalid token ID', ))]
fn test_transfer() {
    let erc404_address = deploy_contract('ERC404');
    let erc404 = IERC404Dispatcher { contract_address: erc404_address };

    let owner = contract_address_const::<'owner'>();
    start_prank(CheatTarget::One(erc404_address), owner);

    let recipient = contract_address_const::<'recipient'>();
    let amount: u256 = 5_000_000_000_000_000_000;

    erc404.transfer(recipient, amount);

    assert(erc404.balance_of(recipient) == amount, 'wrong balance of recipient');
    assert(erc404.owner_of(1) == recipient, 'wrong token id 1');
    assert(erc404.owner_of(2) == recipient, 'wrong token id 2');

    let recipient2 = contract_address_const::<'recipient2'>();
    let amount2: u256 = 2_000_000_000_000_000_000;

    println!("===============================");
    println!("get owned {}", erc404.get_owned(recipient)[0]);
    println!("get owned {}", erc404.get_owned(recipient)[1]);
    println!("get owned {}", erc404.get_owned(recipient)[2]);
    println!("get owned {}", erc404.get_owned(recipient)[3]);
    println!("get owned {}", erc404.get_owned(recipient)[4]);

    start_prank(CheatTarget::One(erc404_address), recipient);
    erc404.transfer_from(recipient, recipient2, 2);
    erc404.transfer(recipient2, amount2);
    // erc404.transfer(recipient2, 100_000_000_000_000_000);

    assert(erc404.owner_of(2) == recipient2, 'wrong token id 1');

    println!("===============================");
    println!("get owned {}", erc404.get_owned(recipient)[0]);
    println!("get owned {}", erc404.get_owned(recipient)[1]);

    println!("2 get owned {}", erc404.get_owned(recipient2)[0]);
    println!("2 get owned {}", erc404.get_owned(recipient2)[1]);
    println!("2 get owned {}", erc404.get_owned(recipient2)[2]);

    println!("===============================");
    println!("token id index {}", erc404.get_owned_index(1));
    println!("token id index {}", erc404.get_owned_index(5));

    println!("token id index {}", erc404.get_owned_index(2));
    println!("token id index {}", erc404.get_owned_index(6));
    println!("token id index {}", erc404.get_owned_index(7));


    println!("uri {}", erc404.token_uri(6)[0]);
    println!("uri {}", erc404.token_uri(6)[1]);
    println!("uri {}", erc404.token_uri(6)[2]);


// println!("get owned {}", erc404.get_owned(recipient2)[0]);
// println!("get owned {}", erc404.get_owned(recipient)[5]);

// println!("owner of 1 {}", erc404.owner_of(1));

// erc404.owner_of(0);
// #[feature("safe_dispatcher")] // Mandatory tag since cairo 2.5.0
// match erc404.owner_of(0).map_string_error() {
//     Result::Ok(_) => panic_with_felt252('shouldve panicked'),
//     Result::Err(panic_data) => {
//         // assert(*panic_data.at(0) == 'PANIC', *panic_data.at(0));
//         // assert(*panic_data.at(1) == 'DAYTAH', *panic_data.at(1));
//     }
// };
}

