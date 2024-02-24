use starknet::ContractAddress;

#[starknet::interface]
trait IERC404<TState> {
    // IERC404
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amountOrId: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amountOrId: u256) -> bool;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;

    // IERC404Metadata
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn token_uri(self: @TState, token_id: u256) -> Array<felt252>;

    // IERC404CamelOnly
    fn totalSupply(self: @TState) -> u256;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amountOrId: u256
    ) -> bool;
    fn ownerOf(self: @TState, tokenId: u256) -> ContractAddress;
    fn safeTransferFrom(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        tokenId: u256,
        data: Span<felt252>
    );
    fn setApprovalForAll(ref self: TState, operator: ContractAddress, approved: bool);
    fn getApproved(self: @TState, tokenId: u256) -> ContractAddress;
    fn isApprovedForAll(self: @TState, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;

    // IERC404External
    fn whitelist(self: @TState, target: ContractAddress) -> bool;
    fn set_whitelist(ref self: TState, target: ContractAddress, state: bool);
    fn get_owner(self: @TState) -> ContractAddress;
    fn set_owner(ref self: TState, new_owner: ContractAddress);
    fn get_owned(self: @TState, owner: ContractAddress) -> Array<u256>;
    fn get_owned_index(self: @TState, token_id: u256) -> u32;
}


#[starknet::contract]
mod ERC404 {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use openzeppelin::token::erc721::interface;
    use openzeppelin::account;
    use openzeppelin::introspection::dual_src5::{DualCaseSRC5, DualCaseSRC5Trait};
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::dual721_receiver::{
        DualCaseERC721Receiver, DualCaseERC721ReceiverTrait
    };
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::Zeroable;

    use core::panic_with_felt252;
    use core::integer::BoundedInt;

    use alexandria_storage::list::{List, ListTrait};

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        minted: u256,
        ERC20_balances: LegacyMap<ContractAddress, u256>,
        ERC20_allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        ERC721_owners: LegacyMap<u256, ContractAddress>,
        ERC721_token_approvals: LegacyMap<u256, ContractAddress>,
        ERC721_operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        ERC721_owned: LegacyMap<ContractAddress, List<u256>>,
        ERC721_owned_index: LegacyMap<u256, u32>,
        whitelist: LegacyMap<ContractAddress, bool>,
        owner: ContractAddress,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ERC20Transfer: ERC20Transfer,
        Approval: Approval,
        Transfer: Transfer,
        ERC721Approval: ERC721Approval,
        ApprovalForAll: ApprovalForAll,
    }

    #[derive(Drop, starknet::Event)]
    struct ERC20Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ERC721Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool
    }


    mod Errors {
        const INVALID_TOKEN_ID: felt252 = 'ERC404: invalid token ID';
        const UNAUTHORIZED: felt252 = 'ERC404: unauthorized caller';
        const APPROVAL_TO_OWNER: felt252 = 'ERC404: approval to owner';
        const SELF_APPROVAL: felt252 = 'ERC404: self approval';
        const INVALID_RECEIVER: felt252 = 'ERC404: invalid receiver';
        const ALREADY_MINTED: felt252 = 'ERC404: token already minted';
        const WRONG_SENDER: felt252 = 'ERC404: wrong sender';
        const SAFE_TRANSFER_FAILED: felt252 = 'ERC404: safe transfer failed';
        const APPROVE_FROM_ZERO: felt252 = 'ERC404: approve from 0';
        const APPROVE_TO_ZERO: felt252 = 'ERC404: approve to 0';
        const NOT_OWNER: felt252 = 'ERC404: NOT_OWNER';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        owner: ContractAddress
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.total_supply.write(total_supply);
        self.owner.write(owner);

        self.ERC20_balances.write(owner, total_supply);
        self.whitelist.write(owner, true);
    }

    #[abi(embed_v0)]
    impl ERC404Impl of super::IERC404<ContractState> {
        // IERC404
        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.ERC20_balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.ERC20_allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amountOrId: u256
        ) -> bool {
            let caller = get_caller_address();

            if (amountOrId <= self.minted.read()) {
                assert(self._is_approved_or_owner(caller, amountOrId), Errors::UNAUTHORIZED);

                self._transfer_ERC721(sender, recipient, amountOrId);

                // erc20 transfer
                let unit = self._get_unit();
                self.ERC20_balances.write(sender, self.ERC20_balances.read(sender) - unit);
                self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + unit);
                self.emit(ERC20Transfer { from: sender, to: recipient, amount: unit });

                // update _owned for sender
                let mut sender_owned_list = self.ERC721_owned.read(sender);
                let update_id = sender_owned_list[sender_owned_list.len() - 1];

                let transfer_id_index = self.ERC721_owned_index.read(amountOrId);
                sender_owned_list.set(transfer_id_index, update_id);
                // pop
                sender_owned_list.pop_front();
                //update index for moved id
                self.ERC721_owned_index.write(update_id, transfer_id_index);
                // append token id to owned
                let mut recipient_owned_list = self.ERC721_owned.read(recipient);
                recipient_owned_list.append(amountOrId);
                // update index for to owned
                self.ERC721_owned_index.write(amountOrId, recipient_owned_list.len() - 1);
            } else {
                let current_allowance = self.allowance(sender, caller);
                if (current_allowance != BoundedInt::max()) {
                    self._approve_erc20(sender, caller, current_allowance - amountOrId);
                }
                self._transfer(sender, recipient, amountOrId);
            }
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amountOrId: u256) -> bool {
            let caller = get_caller_address();

            if (amountOrId <= self.minted.read() && amountOrId > 0) {
                let owner = self._owner_of(amountOrId);
                assert(
                    owner == caller || self.is_approved_for_all(owner, caller), Errors::UNAUTHORIZED
                );
                self._approve(spender, amountOrId);
            } else {
                self._approve_erc20(caller, spender, amountOrId);
            }
            true
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self.transfer_from(from, to, token_id);
            assert(
                _check_on_erc721_received(from, to, token_id, data), Errors::SAFE_TRANSFER_FAILED
            );
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(get_caller_address(), operator, approved);
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            self.ERC721_token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.ERC721_operator_approvals.read((owner, operator))
        }

        // IERC404Metadata
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            18
        }
        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            let mut uri_array = ArrayTrait::<felt252>::new();
            uri_array.append('https://raw.githubusercontent');
            uri_array.append('.com/StarkParadise/Anime/main/');
            uri_array.append(token_id.try_into().unwrap());
            uri_array
        }

        // IERC404CamelOnly
        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply()
        }
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }
        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amountOrId: u256
        ) -> bool {
            self.transfer_from(sender, recipient, amountOrId)
        }
        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.owner_of(tokenId)
        }
        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            self.safe_transfer_from(from, to, tokenId, data)
        }
        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            self.set_approval_for_all(operator, approved)
        }
        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.get_approved(tokenId)
        }
        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.is_approved_for_all(owner, operator)
        }
        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            self.token_uri(tokenId)
        }

        // IERC404External
        fn whitelist(self: @ContractState, target: ContractAddress) -> bool {
            self.whitelist.read(target)
        }

        fn set_whitelist(ref self: ContractState, target: ContractAddress, state: bool) {
            let caller = get_caller_address();
            self._only_owner(caller);
            self.whitelist.write(target, state)
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            let caller = get_caller_address();
            self._only_owner(caller);
            self.owner.write(new_owner);
        }

        fn get_owned(self: @ContractState, owner: ContractAddress) -> Array<u256> {
            let mut owned_list = self.ERC721_owned.read(owner);
            owned_list.array().unwrap()
        }

        fn get_owned_index(self: @ContractState, token_id: u256) -> u32 {
            self.ERC721_owned_index.read(token_id)
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.ERC721_owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252(Errors::INVALID_TOKEN_ID)
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self.ERC721_owners.read(token_id).is_zero()
        }

        fn _only_owner(self: @ContractState, caller: ContractAddress) {
            assert(self.owner.read() == caller, Errors::NOT_OWNER);
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = self.is_approved_for_all(owner, spender);
            owner == spender || is_approved_for_all || spender == self.get_approved(token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, Errors::APPROVAL_TO_OWNER);

            self.ERC721_token_approvals.write(token_id, to);
            self.emit(ERC721Approval { owner, spender: to, token_id });
        }

        fn _approve_erc20(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), Errors::APPROVE_FROM_ZERO);
            assert(!spender.is_zero(), Errors::APPROVE_TO_ZERO);
            self.ERC20_allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, amount });
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, Errors::SELF_APPROVAL);
            self.ERC721_operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }


        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let unit = self._get_unit();
            let balance_before_sender = self.balance_of(sender);
            let balance_before_recipient = self.balance_of(recipient);

            self.ERC20_balances.write(sender, self.ERC20_balances.read(sender) - amount);
            self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + amount);

            // Skip burn for certain addresses to save gas
            if (!self.whitelist(sender)) {
                let tokens_to_burn = (balance_before_sender / unit)
                    - (self.ERC20_balances.read(sender) / unit);

                let mut i: u256 = 0;

                loop {
                    if i == tokens_to_burn {
                        break ();
                    }
                    // burn
                    self._burn(sender);
                    i = i + 1;
                }
            }

            // Skip minting for certain addresses to save gas
            if (!self.whitelist(recipient)) {
                let tokens_to_mint = (self.ERC20_balances.read(recipient) / unit)
                    - (balance_before_recipient / unit);

                let mut i: u256 = 0;

                loop {
                    if i == tokens_to_mint {
                        break ();
                    }
                    // mint
                    self._mint(recipient);
                    i = i + 1;
                }
            }

            self.emit(ERC20Transfer { from: sender, to: recipient, amount })
        }


        fn _transfer_ERC721(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            let owner = self._owner_of(token_id);
            assert(from == owner, Errors::WRONG_SENDER);

            self.ERC721_token_approvals.write(token_id, starknet::Zeroable::zero());
            self.ERC721_owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }


        fn _get_unit(self: @ContractState) -> u256 {
            1_000_000_000_000_000_000
        }


        fn _burn(ref self: ContractState, from: ContractAddress) {
            assert(!from.is_zero(), Errors::WRONG_SENDER);
            let mut from_owned_list = self.ERC721_owned.read(from);
            let id = from_owned_list[from_owned_list.len() - 1];
            from_owned_list.pop_front();

            self.ERC721_owned_index.write(id, 0);
            self.ERC721_owners.write(id, starknet::Zeroable::zero());
            self.ERC721_token_approvals.write(id, starknet::Zeroable::zero());

            self.emit(Transfer { from, to: starknet::Zeroable::zero(), token_id: id });
        }

        fn _mint(ref self: ContractState, to: ContractAddress) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            self.minted.write(self.minted.read() + 1);
            let id = self.minted.read();
            assert(!self._exists(id), Errors::ALREADY_MINTED);

            let mut to_owned_list = self.ERC721_owned.read(to);
            to_owned_list.append(id);

            self.ERC721_owners.write(id, to);

            self.ERC721_owned_index.write(id, to_owned_list.len() - 1);

            self.emit(Transfer { from: starknet::Zeroable::zero(), to, token_id: id });
        }
    }


    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
    ) -> bool {
        if (DualCaseSRC5 { contract_address: to }
            .supports_interface(interface::IERC721_RECEIVER_ID)) {
            DualCaseERC721Receiver { contract_address: to }
                .on_erc721_received(
                    get_caller_address(), from, token_id, data
                ) == interface::IERC721_RECEIVER_ID
        } else {
            DualCaseSRC5 { contract_address: to }.supports_interface(account::interface::ISRC6_ID)
        }
    }
}
