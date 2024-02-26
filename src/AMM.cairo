use starknet::ContractAddress;


#[starknet::interface]
trait IAMM<TContractState> {
    fn swap(ref self: TContractState, token_in: ContractAddress, amount_in: u256);
    fn add_liquidity(ref self: TContractState, amount0: u256, amount1: u256);
    fn remove_liquidity(ref self: TContractState);
    fn get_token0(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod AMM {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    #[storage]
    struct Storage {
        token0: IERC20Dispatcher,
        token1: IERC20Dispatcher,
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token0: ContractAddress,
        token1: ContractAddress,
        owner: ContractAddress
    ) {
        self.token0.write(IERC20Dispatcher { contract_address: token0 });
        self.token1.write(IERC20Dispatcher { contract_address: token1 });
        self.owner.write(owner);
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _only_owner(self: @ContractState, caller: ContractAddress) {
            assert(caller == self.owner.read(), 'wrong caller');
        }
    }


    #[abi(embed_v0)]
    impl AMMImpl of super::IAMM<ContractState> {
        fn swap(ref self: ContractState, token_in: ContractAddress, amount_in: u256) {
            let caller = get_caller_address();
            let this = get_contract_address();

            let (token0, token1) = (self.token0.read(), self.token1.read());
            let (reserve0, reserve1): (u256, u256) = (
                token0.balance_of(this), token1.balance_of(this)
            );

            assert(amount_in > 0, 'wrong amount in');
            assert(
                token_in == token0.contract_address || token_in == token1.contract_address,
                'wrong token in'
            );

            // check token in and token out
            let is_token0: bool = token_in == token0.contract_address;
            let (
                token_in, token_out, reserve_in, reserve_out
            ): (IERC20Dispatcher, IERC20Dispatcher, u256, u256) =
                if (is_token0) {
                (token0, token1, reserve0, reserve1)
            } else {
                (token1, token0, reserve1, reserve0)
            };

            // calculate amount out
            token_in.transfer_from(caller, this, amount_in);
            let amount_out = (reserve_out * amount_in) / (reserve_in + amount_in);
            token_out.transfer(caller, amount_out);
        }


        fn add_liquidity(ref self: ContractState, amount0: u256, amount1: u256) {
            let caller = get_caller_address();
            let this = get_contract_address();

            self._only_owner(caller);
            let (token0, token1) = (self.token0.read(), self.token1.read());

            token0.transfer_from(caller, this, amount0);
            token1.transfer_from(caller, this, amount1);
        }


        fn remove_liquidity(ref self: ContractState) {
            let caller = get_caller_address();
            let this = get_contract_address();

            self._only_owner(caller);
            let (token0, token1) = (self.token0.read(), self.token1.read());

            token0.transfer(caller, token0.balance_of(this));
            token1.transfer(caller, token1.balance_of(this));
        }

        fn get_token0(self: @ContractState) -> ContractAddress {
            self.token0.read().contract_address
        }
    }
}
