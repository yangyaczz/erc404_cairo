use erc404_cairo::ERC404::IERC404Dispatcher;
use erc404_cairo::ERC404::IERC404DispatcherTrait;


use starknet::ContractAddress;
use starknet::contract_address_const;


use snforge_std::{declare, ContractClassTrait, start_prank, CheatTarget};
use snforge_std::errors::{SyscallResultStringErrorTrait, PanicDataOrString};

use traits::TryInto;

use core::serde::Serde;

const NAME: felt252 = 'testtoken404';
const SYMBOL: felt252 = 'tt404';
const TOTALSUPPLY: u256 = 10_000_000_000_000_000_000_000;
const UNIT: u256 = 1_000_000_000_000_000_000;
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

    // msgsender won't work
    // let contract_address = contract.precalculate_address(@call_data);
    // let owner = contract_address_const::<'owner'>();
    // start_prank(CheatTarget::One(contract_address), owner);

    contract.deploy(@call_data).unwrap()
}


#[test]
#[ignore]
fn test_init() {
    let erc404_address = deploy_contract('ERC404');
    let erc404 = IERC404Dispatcher { contract_address: erc404_address };

    assert(erc404.name() == NAME, 'wrong name');
    assert(erc404.symbol() == SYMBOL, 'wrong symbol');
    assert(erc404.total_supply() == TOTALSUPPLY, 'wrong total supply');
    assert(erc404.balance_of(OWNER.try_into().unwrap()) == TOTALSUPPLY / 2, 'wrong owner balance');
    assert(erc404.balance_of(erc404_address) == TOTALSUPPLY / 2, 'wrong owner balance');
    assert(erc404.whitelist(OWNER.try_into().unwrap()), 'wrong whitelist');

    // check rarity
    let mut i = 1;
    loop {
        if i == 5 {
            break ();
        }
        println!("rarity {}", erc404.token_uri(i)[0]);
        println!("rarity {}", erc404.token_uri(i)[1]);
        println!("rarity {}", erc404.token_uri(i)[2]);
        println!("rarity {}", erc404.token_uri(i)[3]);
        println!("rarity {}", erc404.token_uri(i)[4]);
        println!("=================================");
        println!("get_rarity {}", erc404.get_rarity(i));
        i = i + 1;
    };

    let user1 = contract_address_const::<'user1'>();
    start_prank(CheatTarget::One(erc404_address), user1);

    erc404.claim();
    assert(erc404.balance_of(user1) == UNIT, 'wrong claim');

    erc404.claim();
    erc404.claim();
    erc404.claim();

    println!("get_branch_rarity {}", erc404.get_branch_rarity(user1)[0]);
    println!("get_branch_rarity {}", erc404.get_branch_rarity(user1)[1]);
    println!("get_branch_rarity {}", erc404.get_branch_rarity(user1)[2]);
    println!("get_branch_rarity {}", erc404.get_branch_rarity(user1)[3]);
}


#[test]
// #[should_panic(expected: ('ERC721: invalid token ID', ))]
fn test_transfer_and_owner() {
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

    println!("===============================");
    println!("recipient get owned {}", erc404.get_owned(recipient)[0]);
    println!("recipient get owned {}", erc404.get_owned(recipient)[1]);
    println!("recipient get owned {}", erc404.get_owned(recipient)[2]);
    println!("recipient get owned {}", erc404.get_owned(recipient)[3]);
    println!("recipient get owned {}", erc404.get_owned(recipient)[4]);
    println!("===============================");

    let recipient2 = contract_address_const::<'recipient2'>();
    let amount2: u256 = 2_000_000_000_000_000_000;

    start_prank(CheatTarget::One(erc404_address), recipient);
    erc404.transfer_from(recipient, recipient2, 2);
    erc404.transfer(recipient2, amount2);
    assert(erc404.owner_of(2) == recipient2, 'wrong token id 1');

    println!("===============================");
    println!("recipient1 get owned {}", erc404.get_owned(recipient)[0]); // 1
    println!("recipient1 get owned {}", erc404.get_owned(recipient)[1]); // 5
    println!("recipient2 get owned {}", erc404.get_owned(recipient2)[0]); // 2
    println!("recipient2 get owned {}", erc404.get_owned(recipient2)[1]); // 6
    println!("recipient2 get owned {}", erc404.get_owned(recipient2)[2]); // 7
    println!("===============================");

    println!("token id index {}", erc404.get_owned_index(1)); // 0
    println!("token id index {}", erc404.get_owned_index(5)); // 1
    println!("token id index {}", erc404.get_owned_index(2)); // 0
    println!("token id index {}", erc404.get_owned_index(6)); // 1
    println!("token id index {}", erc404.get_owned_index(7)); // 2
}

