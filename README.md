# ERC404 on Starknet

## Intro
This is the cairo implementation version of ERC404. And this is a combination of ERC20 and ERC721.
Every time a user reaches 1 unit(1 * 10 ** 18), he owns 1 nft. He can also transfer it like ERC20.
As conclusion, user can swap it in amm dex like ERC20, also user can list or offer it in marketplace like ERC721. 

Enjoy it for free on testnet. [Starknet ERC404](https://erc404-cairo-frontend.vercel.app/)

***
## script
### init
```
snforge test  \  scarb build
```
***
### declare contract
```
starkli declare target/dev/erc404_cairo_ERC404.contract_class.json --keystore ./keystore.json --account ./account.json
```
***
#### respond:
`
Declaring Cairo 1 class: 0x0632a3b3f136a77bfe137f49850e5fbe3a1fa0942dbf737bdace1541f3ab07fa
Compiling Sierra class to CASM with compiler version 2.4.0...
`
### deploy contract
```
starkli deploy --keystore ./keystore.json --account ./account.json 0x0632a3b3f136a77bfe137f49850e5fbe3a1fa0942dbf737bdace1541f3ab07fa str:TEST404 str:TT404 u256:10000000000000000000000 0x2a04b0c98668a48507e1c02a8f908c4023f5e05e28848572aef0910a0fa2250
```
***
#### respond:
`
Deploying class 0x0632a3b3f136a77bfe137f49850e5fbe3a1fa0942dbf737bdace1541f3ab07fa with salt 0x07ef8d927c29594355326bf57c73b15a302c27c1b5f8f0a28fe3c2d7b9485851...
The contract will be deployed at address 0x0180624f9918dc685cdc3cc2b31bb21b268fd9abc878d40fa1b487bff0f4bbcd
Contract deployment transaction: 0x074995ef2b118214500c834ba1e416e552ea42cc10bb432f9e9b44cafe22196b
Contract deployed:
0x0180624f9918dc685cdc3cc2b31bb21b268fd9abc878d40fa1b487bff0f4bbcd
`
***
### goerli contract detail:
#### owner: `0x2a04b0c98668a48507e1c02a8f908c4023f5e05e28848572aef0910a0fa2250`
#### class: `0x0632a3b3f136a77bfe137f49850e5fbe3a1fa0942dbf737bdace1541f3ab07fa`
#### erc404 contract: `0x0180624f9918dc685cdc3cc2b31bb21b268fd9abc878d40fa1b487bff0f4bbcd`
#### eth contract: `0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7`
#### ammdex contract: `0x02a33096a5709ace5c41edc9e66926104caa607d31bea298cc96127270ad2313`
#### nftmarket contract: `0x009cc31c2c057ffe2b34b7e2b34f7080c59868d4596bf797dfd91358137dbee4`

