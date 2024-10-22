module contracts::intro;

use sui::object::UID;

use std::string::String;

// Errors
const ENotAdmin: u64 = 0;


const ADMIN: address = @0x12345;


public struct AdminCap has key, store {
    id: UID,
}

public struct Person has key {
    id: UID,
    name: String,
    weight: u64,
    prim1: address,
    prim2: bool,
    prim3: u8,
    v1: vector<u8>,
    v2: vector<u64>,
}

fun init(ctx: &mut TxContext) {
    let cap = AdminCap {
        id: object::new(ctx)
    };

    transfer::public_transfer(cap, ctx.sender());
}


public fun add_weight(person: &mut Person, amount: u64) {
    person.weight = person.weight + amount;
}

public fun get_weight(person: &Person): u64 {
    person.weight
}

public fun mint_person(_cap: &AdminCap, name: String, weight: u64, ctx: &mut TxContext): Person {
    assert!(ctx.sender() == ADMIN, ENotAdmin);

    let person = Person {
        id: object::new(ctx),
        name,
        weight,
        prim1: @0xaabbcc,
        prim2: true,
        prim3: 255,
        v1: vector[123u8, 25u8],
        v2: vector[2u64, 20000u64]
    };

    person

}

public fun kill_person(person: Person) {
    let Person {
        id, name:_, weight: _, prim1: _, prim2: _, prim3, v1, v2} = person;
    object::delete(id);

}
