use erc404_cairo::ERC404::IERC404Dispatcher;
use erc404_cairo::ERC404::IERC404DispatcherTrait;

use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

use erc404_cairo::AMM::{IAMMDispatcher, IAMMDispatcherTrait};

use starknet::ContractAddress;
use starknet::contract_address_const;
use core::integer::BoundedInt;

use snforge_std::{declare, ContractClassTrait, start_prank, CheatTarget};
use snforge_std::errors::{SyscallResultStringErrorTrait, PanicDataOrString};

use traits::{TryInto, Into};
// use starknet::Into;

use core::serde::Serde;


const NAME20: felt252 = 'ts20';
const SYMBOL20: felt252 = 'ts20';
const FIXEDSUPPLY20: u256 = 10_000_000_000_000_000_000_000;
const OWNER: felt252 = 'owner';


const NAME404: felt252 = 'testtoken404';
const SYMBOL404: felt252 = 'tt404';
const TOTALSUPPLY404: u256 = 10_000_000_000_000_000_000_000;
const UNIT: u256 = 1_000_000_000_000_000_000;


fn deploy_contract20(name: felt252) -> ContractAddress {
    let contract = declare(name);

    let mut call_data: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@NAME20, ref call_data);
    Serde::serialize(@SYMBOL20, ref call_data);
    Serde::serialize(@FIXEDSUPPLY20, ref call_data);
    Serde::serialize(@OWNER, ref call_data);

    contract.deploy(@call_data).unwrap()
}

fn deploy_contract404(name: felt252) -> ContractAddress {
    let contract = declare(name);

    let mut call_data: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@NAME404, ref call_data);
    Serde::serialize(@SYMBOL404, ref call_data);
    Serde::serialize(@TOTALSUPPLY404, ref call_data);
    Serde::serialize(@OWNER, ref call_data);

    contract.deploy(@call_data).unwrap()
}


#[test]
fn test_init() {
    let ts20_address = deploy_contract20('TEST20');
    let ts20 = ERC20ABIDispatcher { contract_address: ts20_address };

    let ts404_address = deploy_contract404('ERC404');
    let ts404 = IERC404Dispatcher { contract_address: ts404_address };

    assert(ts20.name() == NAME20, 'wrong name');
    assert(ts20.symbol() == SYMBOL20, 'wrong symbol');
    assert(ts20.total_supply() == FIXEDSUPPLY20, 'wrong total supply');
    assert(ts20.balance_of(OWNER.try_into().unwrap()) == FIXEDSUPPLY20, 'wrong owner balance');

    assert(ts404.name() == NAME404, 'wrong name');
    assert(ts404.symbol() == SYMBOL404, 'wrong symbol');
    assert(ts404.total_supply() == TOTALSUPPLY404, 'wrong total supply');

    let owner = contract_address_const::<'owner'>();
    start_prank(CheatTarget::All, owner);

    let amm_contract = declare('AMM');
    let amm_contract_address = amm_contract
        .deploy(@array![ts20_address.into(), ts404_address.into(), owner.into()])
        .unwrap();
    let amm = IAMMDispatcher { contract_address: amm_contract_address };

    /////////////////////////////////////
    let tk0: u256 = 100000000000;
    let tk1: u256 = 100000000000;

    println!("balance of ts20 owner {}", ts20.balance_of(owner));
    println!("balance of ts404 owner {}", ts404.balance_of(owner));

    ts20.approve(amm_contract_address, BoundedInt::max());
    ts404.approve(amm_contract_address, BoundedInt::max());

    let a: felt252 = ts20_address.into();

    println!("inout token0 {}", a);

    let b: felt252 = amm.get_token0().into();
    println!("call amm token0 {}", b);
// amm.add_liquidity(tk0, tk1);
// amm.remove_liquidity();
}

