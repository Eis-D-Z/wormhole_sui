#[test_only]
module loyalty_contracts::loyalty_tests;

use sui::coin;
use sui::clock::{Self, Clock};
use sui::package;
use sui::sui::SUI;
use sui::test_scenario::{Self as ts, Scenario};

use wormhole::setup::{Self, DeployerCap};
use wormhole::state::State;
use wormhole::emitter::{Self, EmitterCap};

use loyalty_contracts::loyalty::{Self, LoyaltyData};
use loyalty_contracts::messages;

const ADMIN: address = @0xABC;

#[test_only]
public fun start(): Scenario {
    let mut scn = ts::begin(ADMIN);
    {
        setup::init_test_only(scn.ctx());
        let cl = clock::create_for_testing(scn.ctx());
        cl.share_for_testing();
        
    };
    
    scn.next_tx(ADMIN);
    {
        let governance_chain: u16 = 1;
        let governance_contract: vector<u8> = vector[
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,
        ];
        let guardian_set_index: u32 = 0;
        let guardian_sets: vector<vector<u8>> = vector[vector[19, 148, 123, 212, 139, 24, 229, 63, 218, 238, 231, 127, 52, 115, 57, 26, 199, 39, 198, 56]];
        let guardian_seconds_to_live: u32 = 86400;
        let message_fee: u64 = 0;
        
        let upgrade_cap =
            package::test_publish(
                object::id_from_address(@wormhole),
                scn.ctx()
        );
        let cap = scn.take_from_sender<DeployerCap>();

        setup::complete(
            cap,
            upgrade_cap,
            governance_chain,
            governance_contract,
            guardian_set_index,
            guardian_sets,
            guardian_seconds_to_live,
            message_fee,
            scn.ctx()
        );

    };

    // create EmitterCap for ADMIN
    scn.next_tx(ADMIN);
    {
        let state = scn.take_shared<State>();

        let emitter_cap = emitter::new(&state, scn.ctx());

        transfer::public_transfer(emitter_cap, ADMIN);
        ts::return_shared(state); 
    };

    scn.next_tx(ADMIN);
    {
        loyalty::init_for_tests(scn.ctx());
    };

    scn
}

#[test]
public fun happy_path() {
    let mut scn = start();
    scn.next_tx(ADMIN);
    {
        let vaa: vector<u8> = vector[1,0,0,0,0,1,0,210,120,57,208,57,168,61,129,237,80,147,88,155,114,165,171,127,115,25,223,91,230,42,184,68,98,124,38,4,234,52,62,28,150,209,201,87,91,124,144,197,198,200,79,35,179,110,36,231,46,27,179,7,66,69,78,89,27,186,216,165,178,166,62,0,103,21,236,16,0,0,12,229,0,1,198,68,42,48,102,139,117,182,49,37,150,238,31,140,254,233,148,45,182,106,7,90,139,199,219,215,201,252,224,252,210,139,0,0,0,0,0,0,0,2,1,40,10,0,0,0,0,0,0,198,68,42,48,102,139,117,182,49,37,150,238,31,140,254,233,148,45,182,106,7,90,139,199,219,215,201,252,224,252,210,139,0,0];
        let state = scn.take_shared<State>();
        let clock = scn.take_shared<Clock>();
        let mut loyalty_data = scn.take_shared<LoyaltyData>();
        messages::receive_message(vaa, &state, &clock, &mut loyalty_data);

        ts::return_shared(state);
        ts::return_shared(clock);
        ts::return_shared(loyalty_data);
    };

    // check user poins
    scn.next_tx(ADMIN);
    {
        let user: vector<u8> = vector[
            198,  68,  42,  48, 102, 139, 117,
            182,  49,  37, 150, 238,  31, 140,
            254, 233, 148,  45, 182, 106,   7,
            90, 139, 199, 219, 215, 201, 252,
            224, 252, 210, 139
        ];
        let data = scn.take_shared<LoyaltyData>();

        let points = data.points(user);

        assert!(points == 2600);

        ts::return_shared(data);
    };

    // send back message with the current amount of points
    scn.next_tx(ADMIN);
    {
        let mut state = scn.take_shared<State>();
        let mut emitter_cap = scn.take_from_sender<EmitterCap>();
        let clock = scn.take_shared<Clock>();
        let loyalty_data = scn.take_shared<LoyaltyData>();
        let user: vector<u8> = vector[
            198,  68,  42,  48, 102, 139, 117,
            182,  49,  37, 150, 238,  31, 140,
            254, 233, 148,  45, 182, 106,   7,
            90, 139, 199, 219, 215, 201, 252,
            224, 252, 210, 139
        ];
        let nonce: u32 = 3301;
        let fee = coin::zero<SUI>(scn.ctx()); // we set fee to 0 for State
        messages::emit_message_(&mut state, fee, &clock, &loyalty_data, user, nonce, &mut emitter_cap);

        ts::return_shared(clock);
        ts::return_shared(loyalty_data);
        ts::return_shared(state);
        scn.return_to_sender(emitter_cap);
    };

    scn.end();
}