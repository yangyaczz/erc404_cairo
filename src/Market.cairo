#[starknet::interface]
trait IMarket<TContractState> {
    fn list(ref self: TContractState, id: u256, value: u256);
    fn buy(ref self: TContractState, id: u256);
    fn cancel(ref self: TContractState, id: u256);
    fn get_branch_price(self: @TContractState) -> Array<u256>;
}

#[starknet::contract]
mod Market {
    use core::array::ArrayTrait;
    use erc404_cairo::ERC404::IERC404Dispatcher;
    use erc404_cairo::ERC404::IERC404DispatcherTrait;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    use starknet::{get_caller_address, get_contract_address, ContractAddress};


    #[storage]
    struct Storage {
        collection: IERC404Dispatcher,
        eth: ERC20ABIDispatcher,
        id_to_value: LegacyMap<u256, u256>,
        id_to_owner: LegacyMap<u256, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        List: List,
        Buy: Buy,
        Cancel: Cancel,
    }

    #[derive(Drop, starknet::Event)]
    struct List {
        #[key]
        owner: ContractAddress,
        #[key]
        id: u256,
        #[key]
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Buy {
        #[key]
        buyer: ContractAddress,
        #[key]
        id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Cancel {
        #[key]
        id: u256,
    }


    #[constructor]
    fn constructor(ref self: ContractState, collection: ContractAddress, eth: ContractAddress) {
        self.collection.write(IERC404Dispatcher { contract_address: collection });
        self.eth.write(ERC20ABIDispatcher { contract_address: eth });
    }

    #[abi(embed_v0)]
    impl MarketImpl of super::IMarket<ContractState> {
        fn list(ref self: ContractState, id: u256, value: u256) {
            let caller = get_caller_address();
            let this = get_contract_address();
            let collection = self.collection.read();

            collection.transfer_from(caller, this, id);
            self.id_to_value.write(id, value);
            self.id_to_owner.write(id, caller);

            self.emit(List { owner: caller, id, value });
        }


        fn buy(ref self: ContractState, id: u256) {
            let caller = get_caller_address();
            let this = get_contract_address();
            let collection = self.collection.read();
            let eth = self.eth.read();

            let value = self.id_to_value.read(id);
            let owner = self.id_to_owner.read(id);

            eth.transfer_from(caller, owner, value);
            collection.transfer_from(this, caller, id);

            self.emit(Buy { buyer: caller, id });
        }
        fn cancel(ref self: ContractState, id: u256) {
            let caller = get_caller_address();
            let this = get_contract_address();
            let owner = self.id_to_owner.read(id);
            assert(caller == owner, 'not owner');

            let collection = self.collection.read();
            collection.transfer_from(this, caller, id);

            self.emit(Cancel { id });
        }
        fn get_branch_price(self: @ContractState) -> Array<u256> {
            let collection = self.collection.read();
            let this = get_contract_address();

            let id_array: Array<u256> = collection.get_owned(this);

            let mut price_array: Array<u256> = ArrayTrait::new();
            let mut i = 0;
            loop {
                if i == id_array.len() {
                    break ();
                }
                let price = self.id_to_value.read(*id_array.at(i));
                price_array.append(price);
                i = i + 1;
            };
            price_array
        }
    }
}
