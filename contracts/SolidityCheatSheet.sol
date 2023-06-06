// SPDX-License-Identifier: GPL-3.0
// ^ Tells that source code is licensed under the GPL version 3.0. Machine-readable license
// It is included as string in the bytecode metadata.

/**
 * pragma solidity x.y.z 
 * "pragma" keyword is used to enable certain compiler features or checks
    where x.y.z indicates the version of the compiler 
        a different y in x.y.z indicates breaking changes & z indicates bug fixes.
    Versioning is to ensure that the contract is not compatible with a new (breaking) compiler version, to avoid behaving differently
 * another e.g. pragma solidity ^0.4.16; -> doesn't compile with a compiler earlier than version 0.4.16, and 
    floating pragma `^` represents it neither compiles on compiler 0.x.0(where x > 4).
    Locking the pragma (for e.g. by not using ^ ahead of pragma) ensures that contracts do not accidentally get deployed using any other compiler version
*/
pragma solidity >=0.4.16 <0.9.0;
// ^ Source code is written for Solidity version 0.4.16, or a newer version of the language up to, but not including version 0.9.0

/**
 * ABI coder (v2) is able to encode and decode arbitrarily nested arrays and structs, 
    can also return multi-dimensional arrays & structs in functions.
 * Default since Solidity 0.8.0 & Has all feature of v1 
*/
pragma abicoder v2;

/**
 *  imports all global symbols from “filename” (and symbols imported there) into current global scope
    not recommended as any items added to the “filename” auto appears in the files
*/
import "./Add.sol";

/**
 * & to import specific symbols explicitly
 * equivalent to -> import * as multiplier from "./Mul.sol";
 */
import "./Mul.sol" as multiplier;

/**
 * External imports are also allowed from github -> import "github/filepath/url"
 * using 'as' keyword while importing to avoid naming collision
 */
//
import {divide2 as div, name} from "./Div.sol";

/**
 * Functions are the executable units of code, usually defined inside a contract, 
    but can also be defined outside of contracts(called Free Functions).
    Free functions cannot have visibility(and are internal by default).
*/
function outsider(uint256 x) pure returns (uint256) {
    return x * 2;
}

// struct can be declared outside contract
struct User {
    address addr;
    string task;
}

/** 
 * Interfaces are similar to abstract, but :
    - They cannot have any functions implemented. 

    - They can inherit from other interfaces but not from contracts

    - All declared functions must be external, even if they are public in the contract.

    - They cannot declare state variables, modifiers or constructor
*/
interface IERC20 {
    enum Type {
        Useful,
        Useless
    }
    struct Demo {
        string dummy;
        uint256 num;
    }

    function transfer(address, uint) external returns (bool);
}

/**
 * Contract is marked as abstract when at least one of it's function is not implemented or 
    when you do not intend for the contract to be created directly 
*/
abstract contract Tesseract {
    function retVal(uint256 x) public virtual returns (uint256);

    function getPriv() external view virtual returns (uint) {
        return 5;
    }
}

// contract inheriting from abstract contract should implement all non-implemented to avoid them being marked as abstract as well.
contract Token is Tesseract {
    uint public totalSupply;
    uint private _anon = 3;

    constructor(uint x) payable {
        require(x >= 100, "Insufficient Supply");
        totalSupply = x;
    }

    function transfer(address, uint) external {}

    /**
     * `virtual` means the function & modifiers can change its behavior in derived class
     * `override` means this function, modifier or state variables has changed its behavior from the base class
     * private function or state variables can't be marked as virtual or override
     */
    function retVal(uint a) public virtual override returns (uint) {
        return a + 10;
    }

    function updateSupply(uint _x) external payable {
        totalSupply = _x + msg.value;
    }

    function _addPriv(uint val) internal view returns (uint) {
        return _anon + val;
    }

    function _mulPriv(uint val) private view returns (uint) {
        return _anon * val;
    }

    function getPriv() external view virtual override returns (uint) {
        return _anon;
    }
}

contract Coin {
    constructor() {}

    function retVal(uint a) public pure virtual returns (uint) {
        return a % 10;
    }
}

/**
 * Inheritance means that components of the parent contracts are "merged" into the child contract
    The parent contracts do not need to be deployed, as everything can be accessed through the child.
    Order of "merging" is that the right most contracts override those on the left.
 * The order of inheritance should start from “most base-like”(least derived, usually an
    interface) to “most derived”.
 * Use of 'is' to derive from another contract
 * Constructors are executed in the following order: Token, Coin & then Currency
*/
contract Currency is
    Token(100),
    Coin // If constructor of ^ Base Contract (the derived contract) accepts arguments ...
{
    constructor() Coin() {} // or through a "modifier" of the derived constructor :

    function intTest() public view returns (uint) {
        return _addPriv(5); // access to internal member (from derived to parent contract)
    }

    /// @inheritdoc Coin Copies all missing tags from the base function (must be followed by the contract name)
    /**
     * Functions can be overridden with the same name, number & types of inputs,  
        change in output parameters causes an error.
     * Override functions can change mutability
        - external to public
        - nonpayable to view/pure
        - view to pure 
     * specify the `virtual` keyword again indicates this function can be overridden again.
     * since Coin is the right most parent contract with this function thus it will internal call Coin.retVal
    */
    function retVal(
        uint a
    ) public pure virtual override(Token, Coin) returns (uint) {
        return super.retVal(a); // ^ Multiple inheritance (Most Derived, least derived Contract)
    }

    /// @notice This function adds 10 to `a`
    //  ^ if _a is assigned 5 this will be rendered as dynamic comment as : This function adds 10 to 5
    /// @param _a followed by parameter's name explain it (only for function, event)
    function xyz(uint _a) public pure {
        super.retVal(_a); // super keyword calls the function one level higher up in the flattened inheritance hierarchy
    }

    // Public state variables can override external getter functions of the variable
    uint public override getPriv;
}

/**
 * Libraries are similar to contracts, but :
        - no state variable 
        - no inheritance
        - cannot hold ether
        - cannot be destroyed
 * A library is embedded into the contract if all library functions are internal 
    and EVM uses JUMP for calling its function similar to a internal function calls

    Otherwise the library must be deployed to unique address and then need to be linked with calling contract
    & thus EVM has to use DELEGATECALL which also prevents libraries from killing 
    by SELFDESTRUCT() as it would brick contracts using the library.
*/
library Root {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }

    /**
     * A library can be attached to a data type inside a contract (only active within that contract:
        - using Root for uint256            attaches all functions of Root to uint256
        - using Root for *                  attaches all functions of Root to all types
        - using { Root.sqrt } for uint256   attaches just sqrt functions of Root to uint256
     * These functions will receive the object they are called on as their first parameter.
     */
    /// @return Documents the return variables of a contract’s function
    function tryMul(
        uint256 a,
        uint256 b
    ) external pure returns (bool, uint256) {
        // after v0.8 unchecked does not let code revert and allows over/under flow arithmetic operations inside it's block
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
}

/**
 * NatSpec is for formatting for contract, interface, library, function & event comments which are understood by Solidity compiler.
 * @title Title describing contract/interface
 * @author Name of author
 * @notice Explain the functionality
 * @dev any extra details for the developer
 * @custom:custom-name tag's explanation
 */
contract SolidityCheatSheet {
    /**
     * All identifiers (contract names, function names and variable names) are restricted to the ASCII character set(0-9,A-Z,a-z & special chars.).
        contract instance of "Token" to interact with it 
     */
    Token _tk; // variable of contract type & can be Explicitly converted to and from the address payable type

    /**
    fallback() or receive ()?

    Ether is sent to contract
            |
    is msg. data empty?
            /  \
          yes   no
          /       \
receive() exists?  fallback()
        /  \
      yes   no
      /      \
receive()   fallback()
*/
    /**
     * Fallback & receive functions must be external.
     * Both can rely on just 2300 gas being available to prevent re-entry
        as this gas is not enough to modify any state
     */
    receive() external payable {
        emit Log("receive", gasleft());
    }

    /**
     * Fallback are executed if none of other function signature is matched,
        can even be defined as non-payable to only receive message call
        fallback can be virtual, override & have modifiers 
    */
    fallback(bytes calldata data) external payable returns (bytes memory) {
        // after v0.8.0, fallback can optionally take bytes as input & also return
        (bool success, bytes memory res) = address(0).call{value: msg.value}(
            data
        );
        require(success, "call failed");
        //returns remaining gas
        return res;
    }

    /**
     * State Variable is like a single slot in a database that are accessible by functions
        and there values are permanently stored in contract storage.
     * Visibility : 
            - public : auto. generates a function that allows to access the state variables even externally
            - internal : can't be accessed externally but only in there defined & derived contracts
            - private : similar to internal but not accessible in derived contracts 
     * private or internal variables only prevents other contracts from accessing the data stored, 
        but it can still be accessible via blockchain
    * State variables can also declared as constant or immutable, values can't modified after contract constructed
    */

    /** 
     * constants doesn't take storage space but is included in contract's bytecode
     * values need to be fixed at compile time 
     * Not allowed any expression like :
        - that accesses storage
        - blockchain data (e.g. block.timestamp, address(this).balance) or 
        - execution data (msg.value or gasleft()) or 
        - making calls to external contracts is disallowed
    */
    string public constant THANOS = "I am inevitable";

    // values can only be assigned in constructor & cannot be read during construction time
    uint public immutable senderBalance;

    /**
     * Variable Packing
     * Multiple state variables depending on their type(that needs less than 32 bytes) can be packed into one slot
     * Packing reduces storage slot usage but increases opcodes necessary to read/write to them.
     */
    uint248 _right; // 31 bytes, Doesn't fit into the previous slot, thus starts with a new one
    uint8 _left; // 1 byte, There's still 1 byte left out of 32 byte slot
    //^ one storage slot will be packed from right to left with the above two variables (lower-order aligned)

    // Structs and array data always start a new slot!

    // Dynamically-sized array's length is stored as the first slot at location p, it's values start being stores at keccak256(p)
    //  one element after the other, potentially sharing storage slots if the elements are not longer than 16 bytes.

    // Mappings leave their slot p empty (to avoid clashes), the values corresponding to key k are stored at
    //  keccak(h(k) + p) with h() padding value to 32 bytes or hashing reference types.

    // Bytes and Strings are stored like array elements and data area is computed using a keccak256 hash of the slot's position.
    // Bytes are stored in continuous memory locations while strings are stored as a sequence of pointers to memory locations
    // For values less than 32 bytes, elements are stored in higher-order bytes (left aligned) and the lowest-order byte stores value (length * 2).
    // whereas bytes of 32 bytes or more, the main slot stores (length * 2 + 1) and the data is stored as usual in keccak256(p).

    // In case of inheritance, order of variables is starting with the most base-ward contract & do share same slot

    /**
        Layout in Memory(Reserves certain areas of memory) :
            -First 64 bytes (0x00 to 0x3f) used for storing temporarily data while performing hash calculations
            - Next 32 bytes (0x40 to 0x5f) also known as "free memory pointer" keeps track of next available location in memory where new data can be stored
            - Next 32 bytes (0x60 to 0x7f) is a zero slot that is used as starting point for dynamic memory arrays that is initialized with 0 and should never be written to.
        New objects in Solidity are always placed at the free memory pointer and memory is never freed.
    */

    // There's no packing in memory or function arguments as they are always padded to 32 bytes
    // Example, following array occupies 32 bytes (1 slot) in storage, but 128 bytes (4 items with 32 bytes each) in memory.
    uint8[4] _slotA;

    // Following struct occupies 96 bytes (3 slots of 32 bytes) in storage, but 128 bytes (4 items with 32 bytes each) in memory.
    struct S {
        uint a;
        uint b;
        uint8 c;
        uint8 d;
    }

    function packing()
        external
        view
        returns (
            uint256 leftSlot,
            uint256 rightSlot,
            bytes32 value,
            uint256 leftOffset,
            uint256 leftValue
        )
    {
        assembly {
            // returns the slot position in storage at which the variable is stored
            // both would return the same slot(because of variable packing sharing same slot)
            leftSlot := _left.slot
            rightSlot := _right.slot

            // fetches value stored at the slot where variable 'right' & 'left'
            // returned value will be concatenated representation of both values (in bytes)
            // e.g. bytes32: value 0x0000000000000000000000000000000200000000000000000000000000000001
            //considering if right = 2 & left = 1
            value := sload(rightSlot)

            // offset tells the exact position (in terms of bytes) in a slot where the variable values start
            leftOffset := _left.offset // will return 31 as the start of variable 'left' will begin where the previous ('right' of 31 bytes) stops

            // To get the value on the leftmost side of the slot, it need to be shifted to right.
            // During shifting the rightmost value will "fall out" of the slot leaving the leftSide filled with zeros.
            // leftOffset of 31 bytes (248 bits) that will be shifted:
            leftValue := shr(mul(leftOffset, 8), value) // 0x0000000000000000000000000000000000000000000000000000000000000002
        }
    }

    /** 
        Value Types : These variables are always be passed by value, 
        i.e. they are always copied when used as function arguments or in assignments.
    */
    // Integers exists in sizes(from 8 up to 256 bits) in steps of 8
    // uint and int are aliases for uint256 and int256, respectively
    uint256 _storedData; // unsigned integer of 256 bits

    // access the minimum and maximum value representable by the integer type
    function integersRange() external pure returns (uint, uint, int, int) {
        return (
            //uintX range
            type(uint8).max, // 2**8 - 1
            type(uint16).min, // 0
            // int : Signed Integer
            // intX range
            type(int32).max, // (2**32)/2 - 1
            type(int64).min // (2**64)/2 * -1
        );
    }

    // address holds 20 byte(160 bits) value and is suitable for storing addresses of contracts, or external accounts.
    address public owner;
    // ^ Equivalent to -> function owner() public view returns (address) { return owner; }
    // address with transfer and send functionality to receive Ether
    address payable public treasury;

    // Boolean holds 1 byte value (0 or 1) possible values are true and false
    bool public isEven;

    function boolTesting(bool _x, bool _y, bool _z) public pure returns (bool) {
        // Short-circuiting rule: full expression will not be evaluated
        // if the result is already been determined by previous variable
        return _x && (_y || _z);
    }

    // bytesN is value data type Fixed size byte array of size N bytes (range : 1 to 32)
    // bytes store every data as hexadecimal format (0x...)
    bytes2 public k;

    function fixedByte() public returns (bytes1) {
        // hex is 4 bits , thus 2 hex characters makes 1 bytes
        k = 0x5661;
        k = "ab"; // stored as 0x6162

        bytes3 j = hex"32"; // stored as 0x320000
        j = "abc";
        // j[0] = "d" Fixed bytes array cannot be

        //can access particular element of byte array
        return (k[0]);
    }

    // Fixed point numbers aren't yet supported and thus can only be declared
    fixed _xFix;
    ufixed _yUfx;

    function literals()
        external
        pure
        returns (
            address,
            uint,
            int,
            uint,
            string memory,
            string memory,
            string memory,
            bytes20,
            int[2] memory
        )
    {
        return (
            // Also Hexadecimal literals that pass the address checksum test are considered as address
            0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF,
            /** 
                Division on integer literals e.g. 5/2
                prior to version 0.4.0 is equal to  2
                but now it's rational number 2.5
            */
            5 / 2 + 1 + 0.5, //  = 4
            // whereas uint x = 1;
            //         uint y = 5/2 + x + 0.5  returns compiler error, as operators works only on common value types

            // decimals fractional formed by . with at least one number after decimal point
            // .1, 1.3 but not 1.
            -.2e10, //Scientific notation of type MeE ~= M * 10**E
            // Underscores have no meaning(just eases human readability)
            1_2e3_0, // = 12*10**30
            // string literal represented in " " OR ' '
            "yo"
            "lo", // can be split = "yolo"
            "abc\\def", // also supports various escape characters
            //unicode
            unicode"Hi there 👋",
            //Random Hexadecimal literal behave just like string literal
            hex"00112233_44556677",
            //  array literals are comma-separated list of one or more expressions
            //  typed by that of its first element & all its elements can be converted this type
            [int(1), -1]
        );
    }

    /** 
        Enums are user-defined type of predefined constants which holds uint8 values (max 256 values)
        First value is default & starts from uint 0
        They can be stored even outside of Contract & in libraries as well
    */
    enum Status {
        Manufacturer,
        Wholesaler,
        Shopkeeper,
        User
    }
    Status public status;

    /** 
        As enums are not stored in ABI
        thus in ABI 'updateStatus()' will have its input type as uint8 
    */
    function updateStatus(Status _status) public {
        status = _status;
    }

    // Accessing boundaries range values of an enum
    function enumsRange() public pure returns (Status, Status) {
        return (
            type(Status).max, // return 3, indicating 'User'
            type(Status).min // return 0, indicating 'Manufacturer'
        );
    }

    /** 
        User Defined Value Types allows creating a zero cost abstraction over an elementary value type
        type C is V , C is new type & V is elementary type
        type conversion , operators aren't allowed 
    */
    type UFixed256x18 is uint256; // Represent a 18 decimal, 256 bit wide fixed point.

    /// custom types only allows wrap and unwrap
    function _customMul(
        UFixed256x18 _x,
        uint256 _y
    ) internal pure returns (UFixed256x18) {
        return
            UFixed256x18.wrap( // wrap (convert underlying type -> custom type)
                UFixed256x18.unwrap(_x) * _y // unwrap (convert custom type -> underlying type)
            );
    }

    /**
        Function Types is a variable that is pointing to a function 
         and parameter of these variable can be used to pass a function as an argument to another function 
         or return a function from a function call.

        variants : 
            - Internal : can only be called inside the current contract(including internal library and inherited functions)
                internal/private/public functions are assignable to internal function type 
            - External : calls originated from other contract, containing  address and a function signature 
                external/public functions are assignable to external function type (excluding libraries function as they use delegatecall)

        Conversion function type A is implicitly convertible to a function type B if :
            * their parameter, return types & visibility are identical
            * state mutability of A is more restrictive than the state mutability of B. 
                - pure functions can be converted to view and non-payable functions
                - view functions can be converted to non-payable functions
                - payable functions can be converted to non-payable functions

        External functions and function types with calldata parameters are incompatible with each other at least one should have memory parameters
    */

    // External & public functions has members
    function f() public payable returns (bytes4) {
        assert(this.f.address == address(this)); //address of the contract where function is located
        this.transferringFunds{gas: 10, value: 800}(payable(address(0))); // specifies amount of gas or ether sent to a function
        return this.f.selector; // returns function selector
    }

    /** 
        Reference Types : Values can be modified through multiple different names unlike Value type
            when passed as an argument or returned in a function, a reference to the value is passed or returned, not a copy.
        always have to define the data locations for the variables
    */

    /** 
        Solidity stores data as :
            1. storage - stored on blockchain as 256-bit to 256-bit key-value store 
            2. memory - is a linear byte-array, addressable at a byte-level 
                    - is modifiable & exists while a function is being called 
                    - can store either 1 or 32 bytes at a time in memory, but can only read in chunks of 32 bytes
            3. calldata - non-modifiable area where function arguments are stored and behaves mostly like memory
        Prior to v0.6.9 data location was limited to calldata in external functions
    */
    function dataLocations(
        uint[] memory memoryArray,
        uint[3] memory secArray
    ) public {
        dynamicSized = memoryArray; // Assignments between storage & memory or from calldata always creates independent copies
        uint[] storage z = dynamicSized; // Assignments to a local storage from storage ,creates reference.
        z.pop(); // modifies array "dynamicSized" through "z"

        // Assignment from memory to memory only create references
        uint[3] memory kl = secArray;
        uint[3] memory j = kl;
        // change to one memory variable are visible in all other memory variable referring same data
        delete j[1];
        assert(kl[1] == j[1]);

        /** 
            delete
                Resets to the default value of that type
                doesn't works on mappings (unless deleting a individual key)
        */
        delete dynamicSized; // clears the array "dynamicSized" & "z"
        delete dynamicSized[2]; // resets third element of array w/o changing length

        /**  
            Assigning memory to local storage doesn't work as
            it would need to create a new temporary / unnamed array in global storage, 
            but storage is allocated at compile time & not runtime
            // z = memoryArray;

            Cannot "delete z" as
            referencing global storage objects can only be made from existing local storage objects.
            // delete z
        */
    }

    /** 
        Structs is a group of multiple related variables ,
        can be passed as parameters only for library functions 
    */
    struct Todo {
        uint[] steps;
        bool initialized;
        address owner;
        uint numTodo;
        User user; // can contain other struct but not itself
        // mapping(uint => address) reader;
    }
    Todo[] public todoArr; // arrays of struct

    function onStruct(uint[] memory _arr, uint _index) external {
        // Initializing
        // 1. initializing individually as reference
        Todo storage t = todoArr[_index];
        t.steps = _arr;
        t.initialized = true;
        t.owner = msg.sender;
        t.user = User(msg.sender, "foo");
        // 2. key: value mapping by creating a struct in memory
        todoArr.push(
            Todo({
                steps: _arr,
                initialized: true,
                owner: msg.sender,
                numTodo: _index,
                user: User(msg.sender, "foo")
            })
        );
        // 3. passing as arguments through struct memory
        todoArr.push(
            Todo(
                _arr,
                true,
                msg.sender,
                _index,
                User({addr: msg.sender, task: "foo"})
            )
        );
        /** 
        4. adds new element to end of array and then set the value of a particular field in that element
            leaving all other fields to there default 
        */
        todoArr.push().numTodo = 45;

        // accessing struct
        t.owner; // returns the value stored 'owner'

        // Struct containing a nested mapping can't be constructed though memory

        // t.reader[_index] = tx.origin;         // WORKS can be initialized by storage reference to struct
        // tx.origin : sender's address of the transaction as transactions can originate only from Externally Owned Account (EOA)
        // Todo({reader[_index]: tx.origin;})  // Error
    }

    // Arrays
    uint[] public dynamicSized; // length of a dynamic array is stored at the first slot of array and followed by its elements
    uint[2 ** 3] _fixedSized; // array of 8 elements all initialized to 0
    uint[][4] _nestedDynamic; // An array of 4 dynamic arrays
    bool[3][] _triDynamic; // Dynamic Array of arrays of length 3
    uint[] public arr = [1, 2, 3]; // pre assigned array
    uint[][] _freeArr; // Dynamic arrays of dynamic array

    function aboutArrays(
        uint _x,
        uint _y,
        uint _value,
        bool[3] memory _newArr,
        uint size
    ) external {
        // Creating memory arrays
        uint[] memory a = new uint[](7); // Fixed size memory array
        uint[2][] memory b = new uint[2][](size); // Dynamic memory array
        // fixed size array can't be converted/assigned to dynamic memory array
        // uint[] memory x = [uint(1), 3, 4]; // gives Error
        // Unlike storage arrays memory or fixed size array can't be resized i.e. push or pop is invalid

        // assigning to arrays
        for (uint i = 0; i <= 7; i++) {
            a[i] = i; // assigning elements individually
        }
        _triDynamic.push(_newArr); // pushes array of 3 element to a Dynamic array

        // arrays in struct
        Todo storage g = todoArr[0]; // reference to 'Todo' in 'g'
        g.steps = a; // changes in 'Todo' also

        // Accessing array's elements
        b[_x][_y]; // returns the element at index 'y' in the 'x' array
        _nestedDynamic[_x]; // returns the array at index 'x'
        arr.length; // number of elements in array

        // Only dynamic storage arrays are resizable
        // Adding elements
        dynamicSized.push(_value); // appends new element at end of array , equivalent dynamicSized.push() = _value;
        dynamicSized.push(); // appends zero-initialized element

        // Removing elements
        dynamicSized.pop(); // remove end of array element
        delete arr; // resets all values to default value
        _triDynamic = new bool[3][](0); // similar to delete array
    }

    /** 
        slicing of array[start:end] 
        start default is 0 & end is array's length 
        only works with calldata array as input
    */
    function slice(
        uint[] calldata _arr,
        uint start,
        uint end
    ) public pure returns (uint[] memory) {
        return _arr[start:end];
    }

    // dynamic sized bytes array and string are special arrays of Reference type
    // bytes represents arbitrary length raw byte data
    // bytes are similar to bytes1[] but tightly packed (w/o padding)
    bytes _tps;

    // String represents dynamic array of UTF-8 characters
    string _kmp;

    function bytesNstring(
        bytes memory _bc,
        string memory _tmc
    ) public returns (uint) {
        _tps = _bc;
        _kmp = _tmc;

        // like array only storage bytes can be resized
        _tps.push(0x61);
        _tps.push("b");
        /**
            only 1 byte can be pushed at a time
            Error: 
                _tps.push('bcd');
                _tps.push(0x6162);
         */
        _tps.pop();

        return _tps.length;
    }

    function bytesOperations(
        string calldata _str,
        bytes2 sm
    ) public pure returns (uint, bytes1, bool, string memory, bytes memory) {
        return (
            // string length & element cannot be accessed directly thus accessing byte-representation of string
            bytes(_str).length, // length of bytes of UTF-8 representation
            bytes(_str)[2], // access element of  UTF-8 representation
            keccak256(abi.encodePacked("foo")) ==
                keccak256(abi.encodePacked("Foo")), //compare two strings
            // concatenate
            string.concat("foo", "bar"),
            bytes.concat(bytes(_str), sm)
        );
    }

    /** 
        Mappings are like hash tables which are virtually initialized such that 
        every possible key is mapped to a value whose byte-representation is all zeros,

        Not possible to obtain a list of all keys or values of a mapping, 
        as keccak256 hash of keys is used to look up value

        only allowed as state variables but can be passed as parameters only for library functions 

        Key Type can be inbuilt value types, bytes, string, enum but not user-defined, mappings, arrays or struct
        Value can of any type
    */
    mapping(address => uint256) public balances;

    /** 
        Operators
            Result type of operation determined based on :
            type of operand to which other operand can be implicitly converted to

       '==' operator is not directly compatible with dynamically-sized types, as the length of these arrays can vary.
        It can only be used to compare values of certain types, such as integers and fixed-size byte arrays. 
    */

    /** 
        Ternary Operator
        if <expression> true ? then evaluate <true Expression>: else evaluate <false Expression> 
    */
    uint _tern = 2 + (block.timestamp % 2 == 0 ? 1 : 0);

    // 1.5 + (true ? 1.5 : 2.5) NOT valid, as _ternary operator doesn't have a rational number type

    // pre and post fix increment and decrement operators are used to increase or decrease the value of a variable by 1.
    function postPreFix()
        external
        pure
        returns (uint r, uint s, uint t, uint u)
    {
        uint p = 10;
        //PostFix : returns the value of the variable before it has been incremented/decremented
        r = p++; // 10
        // now p = 11
        s = p--; // 11

        uint q = 20;

        //PreFix : returns the value of the variable after it has been incremented/decremented
        t = ++q; // 21
        // now q = 21
        u = --q; // 20
    }

    // Bitwise Operator
    function bitwiseOperate(
        uint a,
        uint c
    ) external pure returns (uint, uint, uint, uint, uint, uint) {
        return (
            // AND
            // a     = 1110 = 8 + 4 + 2 + 0 = 14
            // c     = 1011 = 8 + 0 + 2 + 1 = 11
            // a & c = 1010 = 8 + 0 + 2 + 0 = 10
            a & c,
            // OR
            // a     = 1100 = 8 + 4 + 0 + 0 = 12
            // c     = 1001 = 8 + 0 + 0 + 1 = 9
            // a | c = 1101 = 8 + 4 + 0 + 1 = 13
            a | c,
            // NOT
            // a  = 00001100 =   0 +  0 +  0 +  0 + 8 + 4 + 0 + 0 = 12
            // ~a = 11110011 = 128 + 64 + 32 + 16 + 0 + 0 + 2 + 1 = 243
            ~a,
            // XOR -> if bits are same then 0 , if different then 1
            // a     = 1100 = 8 + 4 + 0 + 0 = 12
            // c     = 0101 = 0 + 4 + 0 + 1 = 5
            // a ^ c = 1001 = 8 + 0 + 0 + 1 = 9
            a ^ c,
            // shift left
            // 1 << 0 = 0001 --> 0001 = 1
            // 1 << 1 = 0001 --> 0010 = 2
            // 1 << 2 = 0001 --> 0100 = 4
            // 3 << 2 = 0011 --> 1100 = 12
            a << c,
            // shift right
            // 8  >> 1 = 1000 --> 0100 = 4
            // 8  >> 4 = 1000 --> 0000 = 0
            // 12 >> 1 = 1100 --> 0110 = 6
            a >> c
        );
    }

    function _typeConversion()
        internal
        pure
        returns (uint32 foobar, uint j, uint16 m, bytes1 p)
    {
        /** 
            Implicit Conversions
                compiler auto tries to convert one type to another
                conversion is possible if makes sense semantically & no information is lost
        */
        uint8 foo;
        uint16 bar;
        foobar = foo + bar; // during addition uint8 is implicitly converted to uint16 and then to uint32 during assignment

        /** 
            Explicit Conversions
                if you are confident and forcefully do conversion
                    - converting to a smaller type, higher-order bits are cut off
                    - converting to a larger type, it is padded on the left
        */
        int kt = -3;
        j = uint(kt);

        // when uint is converted to a smaller uint the smallest bytes are taken (from right)
        uint32 l = 0x12345678;
        m = uint16(l); // b will be 0x5678 now
        // uint16 c = 0x123456; //error, since it would have to truncate to 0x5678, since v0.8 only conversion allowed if in resulting range

        // when byte is converted to a smaller byte its taken from the left
        bytes2 n = 0x1234;
        p = bytes1(n); // b will be 0x12
    }

    // Units works only with literal number
    function _units() internal pure {
        // Ether units
        assert(1 wei == 1);
        assert(1 gwei == 1e9);
        assert(1 ether == 1e18);

        // Time
        assert(1 seconds == 1);
        assert(1 minutes == 60 seconds);
        assert(1 hours == 60 minutes);
        assert(1 days == 24 hours);
        assert(1 weeks == 7 days);
        uint t = 5;
        t * 1 days; // as t days doesn't work
    }

    function _blockProperties(
        uint _blockNumber
    )
        internal
        view
        returns (
            bytes32,
            uint,
            uint,
            address,
            uint,
            /**uint,*/ uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        return (
            blockhash(_blockNumber), // hash of block(one of the 256 most recent blocks)
            block.basefee, // current block's base fee
            block.chainid,
            block.coinbase, // current block miner’s address
            block.difficulty, // deprecated for EVM versions previous Paris
            // block.prevrandao(_blockNumber),     // random number provided by the beacon chain (EVM >= Paris)
            block.gaslimit, // current block's gas limit
            block.number,
            block.timestamp, // timestamp as seconds of when block is mined
            gasleft(), // remaining gas
            tx.gasprice // gas price of transaction
        );
    }

    function _encodeDecode(
        uint f,
        uint[3] memory g,
        bytes memory h
    )
        internal
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes32)
    {
        // Encoding
        bytes memory encodedData = abi.encode(f, g, h); // encodes given arguments

        /** 
                This method has no padding, thus one variable can merge into other
                resulting in Hash collision , 
                only useful if types and length of parameters are known
                e.g. encodePacked   (AAA, BBB) -> AAABBB
                                    (AA, ABBB) -> AAABBB
                use abi.encode to solve it
        */
        abi.encodePacked(f, g, h);

        // Decoding
        uint _f;
        uint[3] memory _g;
        bytes memory _h;
        (_f, _g, _h) = abi.decode(encodedData, (uint, uint[3], bytes)); // decodes the encoded bytes data back to original arguments
        assert(_f == f);

        return (
            // encodes arguments from the second and prepends the given four-byte selector
            abi.encodeWithSelector(this.bitwiseOperate.selector, 12, 5), // arguments type is not checked
            abi.encodeWithSignature("bitwiseOperate(uint,uint)", 14, 10), // typo error & arguments is not validated
            // ensures any typo and arguments types match the function signature
            abi.encodeCall(IERC20.transfer, (address(0), 12)),
            /**
                ^ zero address (address(0)) private key is unknown 
                thus Ether and tokens sent to this address cannot be retrieved and setting access control roles to this address also won’t work  
            */

            // Hashing
            keccak256(abi.encodePacked("Solidity"))
            /** 
                similarly :
                    - sha256(bytes memory)
                    - ripemd160(bytes memory) 
            */
        );
    }

    function contractInfo()
        external
        pure
        returns (string memory, string memory, bytes4)
    {
        return (
            // Name of Contract / Interface.
            type(Token).name,
            type(IERC20).name,
            // EIP-165 interface identifier of the given interface
            type(IERC20).interfaceId

            // used to build custom creation routines, especially by using the create2 opcode.
            // type(Test).creationCode,

            // Runtime bytecode of contract that deployed through constructor(assembly code) of other contract.
            // type(Test).runtimeCode
        );
    }

    /** 
        Constructor(is optional) code only runs when the contract is created
        State variables are initialized before the constructor code is executed
        After execution of constructor the final code deployed on chain does not include :
                                                                                - constructor code or 
                                                                                - any internal functions call through it
    */
    constructor(bytes32 _salt) payable {
        // "msg" is a special global variable that contains allow access to the blockchain.
        // msg.sender is always the address where the current (external) function call came from.
        owner = msg.sender;
        senderBalance = owner.balance; // .balance is used to query the balance of address in Wei
        balances[owner] = 100; // assigning value to mapping "balances"
        _createContract(_salt);
    }

    /** 
        - Modifiers can be used to change the behavior of functions 
            in a declarative way(abstract away control flow for logic)

        - Overloading (same modifier name with different parameters) is not possible.
            Like functions, modifiers can be overridden via derived contract(if marked 'virtual')
            Multiple modifiers in functions are evaluated in the order presented 
    */
    modifier onlyOwner() /**can receive arguments*/ {
        require(msg.sender == owner, "Not Owner");
        _; // The function body is inserted where the underscore is placed(can be multiple),
        // any logic mentioned after underscore is executed afterwards
    }

    // Events allow clients to react to specific state change
    // Web app can listen for these events, the listener receives the arguments sender and value, to track transactions.
    // E.g. Listeners using web3js :
    // ContractName.Stored().watch({}, '', function(error, result) {
    // if (!error) {
    //     console.log("Number stored: " + result.args.value +
    //         " stored by " + result.args.sender +".");
    //     }
    // })
    event Stored(address sender, uint256 value);

    /** 
        for filtering certain logs 'indexed'(stores parameter as "topics") attribute can be added up to 3 params
        All parameters without the indexed attribute are ABI-encoded into the data part of the log
        Filtering of events can also be done via the address of contract
    */
    event Log(string func, uint indexed gas);

    /** 
        'anonymous' events can support up to 4 indexed parameters
            - does not stores event's signature as topic
            - not possible to filter for anonymous events by name, but only by the contract address 
            - should be used when contract has only one event such that all logs are known to be from this event 
    */
    event Privacy(
        string indexed rand1,
        string indexed rand2,
        string indexed rand3,
        string indexed rand4
    ) anonymous;

    bytes32 _eventSelector = Log.selector; // stores keccak256 hash of non-anonymous event signature

    // Errors allow custom names and data for failure situations.
    // Are used in revert statement & are cheaper than using string in revert
    error LowValueProvided(uint value);

    function _createContract(bytes32 _salt) internal {
        // Send ether along with the new contract "Token" creation and passing in args to it's constructor
        _tk = new Token{value: msg.value}(3e6);

        /** 
            contract address is computed from creating contract address and nonce 
            while if salt value is given, address is computed from :
            creating contract address, 
            salt & 
            creation bytecode of the created contract and the constructor arguments.
        */
        address preComputeAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            _salt,
                            keccak256(
                                abi.encodePacked(
                                    type(Token).creationCode,
                                    abi.encode(3e6)
                                )
                            )
                        )
                    )
                )
            )
        );

        // Create2 opcode is method to deploy a new contract with a deterministic address
        address c = address(new Token{value: msg.value, salt: _salt}(3e6));

        assert(address(c) == preComputeAddress);
    }

    // Modifier usage let only the creator of the contract "owner" can call this function
    function set(uint256 _value) public onlyOwner {
        if (_value < 10) revert("Low value provided");
        _storedData = _value;

        // Block scoping
        uint insideout = 5;
        {
            insideout = 35; // will assign to the outer variable
            uint insideout; // Warning : Shadow declaration but it's visibility is limited only to this block
            insideout = 1000;
            assert(insideout == 1000);
        }
        assert(insideout == 35); // will check for outer variable

        // Stored event emitted
        emit Stored(msg.sender, _value);
    }

    // Payable Function requires Calling this function along with some Ether (as msg.value)
    function transferringFunds(address payable _to) external payable {
        /** 
            'transfer' fails if sender don't have enough balance or Transaction rejected by receiver 
            reverts on failure & stops execution
            transfer/send has 2300 gas limit to prevent re-entrancy attack
        */
        treasury.transfer(1 wei);

        /** 
            'send' returns a boolean value indicating success or failure.
            doesn't stops execution
            transfer of tokens via 'send' can failed if call stack depth reaches 1024 & also if recipient run out of gas 
        */
        bool sent = payable(0).send(1 wei); // payable(0) -> 0x0000000000000000000000000000000000000000
        require(sent, "Send failed");

        /** 
            Call returns a boolean value indicating success or failure.
            is possible to adjust gas supplied
            most recommended method to transfer funds.
        */
        (bool res, ) = _to.call{gas: 5000, value: msg.value}("");
        require(res, "Failed to send Ether");

        /** 
            Explicit conversion allowed 
            from address to address payable &
            from uint160, bytes20, contract types to address 
        */
        payable(owner).transfer(address(this).balance); // querying current contract balance in Wei
    }

    /** 
        low level function to interact with other contract especially with
        the source code of the called contract is not available in the calling contract
        
        ether and custom gas amount can be sent along

        low level calls are not recommended : 
            - bypasses type checking, function existence check, and argument packing
            - on "revert" cause entire transaction to be reverted (including any changes made prior to low-level call)
    */
    function lowLevelCall(
        address payable _contract
    ) external payable returns (bool success, bytes memory data) {
        // call method , forwards all remaining gas by default
        (success, data) = _contract.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("dummy(string,uint256)", "hello there", 200)
        );

        /**
            delegatecall to other contract execute it's function but preserves calling contract's state (storage, contract address & balance)
            i.e. delegatecall from contract A to B : while the code executed is that of contract B, but execution happens in the context of contract A. 
                Such that any reads or writes to storage affect the storage of A, not B.
            The purpose of delegatecall is to use library code which is stored in another contract as well as used in proxy pattern.
            Prior to v0.5.0 delegatecall is called callcode
        */
        (success, data) = _contract.delegatecall(
            abi.encodeWithSignature("setVar(uint256)", 35)
        );
        /** 
            ^ If state variables are accessed via a low-level delegatecall, 
            the storage layout of the two contracts must be in same order for the called contract to correctly access the storage variables of the calling contract by name. 
        */

        // STATICCALL opcode is used when view/pure functions are called such that modifications to the state are prevented
    }

    // query the deployed code for any smart contract
    function accessCode(
        address _contractAddr
    ) external view returns (bytes memory, bytes32) {
        return (
            _contractAddr.code, // gets the EVM bytecode of code
            _contractAddr.codehash // Keccak-256 hash of that code
        );
    }

    /** 
        Function Visibility : 
            - external : these calls create an actual EVM message call, 
                they can be called from other contracts and via transactions; 
                and can be accessed internally via this.extFunc()
            - public : can be either called internally eg. pubFunc() or via message calls(externally) like this.pubFunc() 
            - internal : can only be accessed from within the current contract or contracts deriving from it & neither exposed via ABI
            - private : similar to internal but not accessible in derived contracts 
    */
    function canUSeeMe() public view returns (uint) {
        /** 
            _tk._anon() , _tk._mulPriv() will not be accessible due to private visibility and 
            also as this contract doesn't derived from contract Token, _tk._addPriv() (internal func.) will also not be accessible 
        */
        return _tk.getPriv();
    }

    function funcCalls(uint[] calldata _data, uint _x, uint _y) public payable {
        // while external contract call we can specify value & gas
        _tk.updateSupply{value: msg.value, gas: 3000}(5);
        /** 
            NOTE : calling contractInstance.{value, gas} w/o () at end , 
            will not call function resulting in loss of value & gas 
        */

        //arguments can be given by name, in any order, if they are enclosed in { }
        slice({end: _y, _arr: _data, start: _x});
    }

    /** Functions Mutability :
        - view : functions which can read state & environment variables but cannot modify it
                    Following are considered as state modifying :
                        - Writing to state variables 
                        - Emitting events 
                        - Creating other contracts 
                        - Using selfdestruct 
                        - Sending Ether via calls 
                        - Calling any function not marked view or pure 
                        - Using low-level calls 
                        - Using inline assembly that contains certain opcodes.

        - pure : functions can neither read or modify state or environment variables (except msg.sig & msg.data),
                    these functions can also use revert as its not considered 'state modification'
    */

    // Contract can have multiple functions of the same name but with different parameter types called 'overloading'
    function twins(uint256 j) public view returns (uint km) {
        km = j * block.timestamp;
    }

    // Returns parameters are not taken into consideration for overload resolution
    function twins(uint8 j) public pure returns (uint km) {
        km = j * 2;
    }

    function arithmeticFlow(
        uint a,
        uint b
    ) public pure returns (uint u, uint o) {
        // This subtraction will wrap on underflow.
        unchecked {
            u = a - b;
        }

        o = a - b; // will revert on underflow
        return (u, o);
    }

    /** 
        Solidity throws an exception if an condition evaluates to false
        resulting in revert to previous state via rolling back all changes made to the state so far.
    */
    function errorFound(address payable addr) public payable {
        /** 
            Require validates :
                - invalid inputs
                - conditions that cannot be detected until execution time
                - return values from calls to other functions
        */
        require(msg.value % 2 == 0, "Value sent not Even");

        // A direct revert can be triggered using the revert statement and the revert function.
        if (msg.value < 1 ether) revert LowValueProvided(msg.value);
        // revert can also be used like revert("description") or revert CustomError(args)

        uint balBeforeTransfer = address(this).balance;
        addr.transfer(msg.value / 2);

        /** 
            Assert should be used at end of function to prevent severe error ,
            especially at statement which should never evaluate to 'false' under normal circumstances in bug free code

            Assert used for:
                - checking Internal errors & invariants
                - validate contract state after making changes
                - check for overflow/underflow
        */
        assert(address(this).balance == balBeforeTransfer - msg.value / 2); // it will fail only if there is any exception while transferring funds

        /** 
            Error(string) is used for regular error conditions
                Error exception is generated :
                - require() and revert() uses 0xfd(REVERT) error code , this refunds any unused gas until now 

                - If require(statement) evaluates to false.

                - If you use revert() or revert("description").

                - If you perform an external function call targeting a contract that contains no code.

                - If your contract receives Ether via a public function without payable modifier (including the constructor and the fallback function).

                - If your contract receives Ether via a public getter function.
        */

        /** 
            Panic(uint256) is used for errors that should not be present in bug-free code
                Panic error generated with error code:
                0x00: Used for generic compiler inserted panics.

                0x01: If you call assert with an argument that evaluates to false.
                assert() uses 0xfe(INVALID) opcode which uses up all gas included in transaction

                0x11: If an arithmetic operation results in underflow or overflow outside of an unchecked { ... } block.

                0x12; If you divide or modulo by zero (e.g. 5 / 0 or 23 % 0).

                0x21: If you convert a value that is too big or negative into an enum type.

                0x22: If you access a storage byte array that is incorrectly encoded.

                0x31: If you call .pop() on an empty array.

                0x32: If you access an array, bytesN or an array slice at an out-of-bounds or negative index (i.e. x[i] where i >= x.length or i < 0).

                0x41: If you allocate too much memory or create an array that is too large.

                0x51: If you call a zero-initialized variable of internal function type.
        */

        /** 
            Cases when it can either cause an Error or a Panic (or whatever else was given):
                - If a .transfer() fails.

                - If calling a function via a message call fails 

                - If the contract creation does not finish properly that was created using 'new'
        */
    }

    /** 
        A failure in an external call or while creating contract can be caught using a try/catch statement
        whenever a "revert" call is executed an exception is generated that propagates up the function call stack 
        until caught by try/catch.
    */
    function tryNcatch(
        address _extContract,
        address _recipient
    ) public returns (bool) {
        try IERC20(_extContract).transfer(_recipient, 100) returns (
            bool success
        ) {
            return (success);
        } catch Error(
            string memory desc // while creating new contract -> try new Token(_totalSupply) returns (Token t)
        ) {
            // This is executed in case revert("string description")
            emit Log(desc, gasleft());
            return (false);
        } catch Panic(uint /**errorCode*/) {
            // executed in case of a panic
            return (false);
        } catch (bytes memory /**lowLevelData*/) {
            // executed in case revert() was used.
            return (false);
        }
    }

    /** 
        sends contract ether balance to the designated address 
        then removes contract code from the blockchain
        but can be retained as it's part of the blockchain's history
        ether can still be sent to the removed contract but would be lost
    */
    function boom() external {
        // some other code ....
        // if boom() reverts before selfdestruct, it "undo" the destruction
        selfdestruct(payable(owner)); // Warning : SELFDESTRUCT is deprecated opcode
        /** 
            When the SELFDESTRUCT opcode is called, ether of the callee are sent to the address on the stack, 
            and execution is immediately halted and functions blocking the receipt of Ether will not be executed.

            self destruct forcefully send eth to contract even if:
                - contract has no payable , receive or fallback functions
                - contract has revert() in receive()
        */
    }

    // accessing library
    function testRoot(uint256 _num) public pure returns (uint) {
        return Root.sqrt(_num);
    }

    /** 
        Inline assembly is way to access EVM at low level(via OPCODES) by passing important safety features & checks of solidity
        it uses Yul as it's language 
    */
    function assemblyTinker(address _addr) public returns (bool) {
        uint256 size;
        // retrieve the size of the code, through assembly
        assembly {
            // variables declared outside assembly block can be manipulated inside
            // assign to variable by :=
            size := extcodesize(_addr) // extcodesize is opcode for length of the contract bytecode(in bytes) at addr

            // no semicolon or new line required
            let a := mload(0x40) // reads and assign (u)int256 from memory at location 0x40
            mstore(a, 2) // writes (u)int256 value 2 as memory to variable 'a'
            sstore(a, 10) // writes (u)int256 value 2 as storage to variable 'a'

            // Supports for loops, if and switch statements and function calls.
            if eq(size, 0) {
                revert(0, 0)
            }

            {
                function switchPower(base, exponent) -> result {
                    switch exponent
                    case 0 {
                        result := 1
                    }
                    case 1 {
                        result := base
                    }
                    default {
                        result := switchPower(mul(base, base), div(exponent, 2))
                        switch mod(exponent, 2)
                        case 1 {
                            result := mul(base, result)
                        }
                    }
                }
            }

            {
                function forPower(base, exponent) -> result {
                    result := 1
                    // variable declarations by let
                    for {
                        let i := 0
                    } lt(i, exponent) {
                        i := add(i, 1)
                    } {
                        // lt opcode is for comparing if i<exponent
                        result := mul(result, base)
                    }
                }
            }
        }
        return (size > 0);
    }

    /** 
        Function parsed data is represented as 4 + 32*N where N is the number of arguments in the function
        
        Function signature is a string that consists of the function's name and the types of its input parameters. 
            also used to distinguish function from another with the same name but different parameters.
            e.g. a function "transfer" with two input parameters address & uint256, signature is "transfer(address,uint256)".
        
        Function selector is a first(left aligned) four-byte of keccak256 hash of function's signature 
            used to identify a specific function in a contract. 

        Function's selector and signature are used together to call a specific function within a contract. 
            as the function selector is included in the data field of the transaction when a call is made to contract 
        The contract uses the function selector to determine which function should be executed, 
            and then checks the signature of the function to ensure that the correct input parameters have been provided.
        
        Argument encoding the process of encoding function arguments into byte array that serves as input data input data to contract's function call
            this input data is later decoded by the contract and are passed to functions in correct format

        for eg. calling following function with params. 
            (53, ["abc", "def"], "dave", true, [1,2,3]) we would pass total 388 bytes as follows :

            - prefix we discard
                0x
            -  function selector/ Method ID (first 4 bytes of selector)
                566145fd
        NOTE : All arguments will be padded to 32 bytes, each arguments are separated by 64 characters(32 bytes)
            -  uint32  "53" as first parameter 
                0000000000000000000000000000000000000000000000000000000000000035
            -  bytes3  "abc" (left-aligned) as first part of second parameter
                6465660000000000000000000000000000000000000000000000000000000000
            -  "def" (left-aligned) as second part of second parameter
                6162630000000000000000000000000000000000000000000000000000000000
            -  dynamic byte, location of data part of third parameter (dynamic type), measured in bytes from the start of argument block
                00000000000000000000000000000000000000000000000000000000000000c0 // 192th Byte
            -  Boolean ‘true’ as fourth parameter
                0000000000000000000000000000000000000000000000000000000000000001
            -  dynamic array, location of data part of fifth parameter (dynamic type), measured in bytes
                0000000000000000000000000000000000000000000000000000000000000100 // 256th Byte
            -  data part of third argument, starts with length of byte array, in this case, 4
                0000000000000000000000000000000000000000000000000000000000000004
            -  data of third argument UTF-8 (equal to ASCII in this case) encoding of "dave", padded on right to 32 bytes
                6461766500000000000000000000000000000000000000000000000000000000
            -  data part of fifth argument, starts with length of array, in this case, 3
                0000000000000000000000000000000000000000000000000000000000000003
            -  first element of fifth parameter
                0000000000000000000000000000000000000000000000000000000000000001
            -  second element of fifth parameter
                0000000000000000000000000000000000000000000000000000000000000002
            -  third element of fifth parameter
                0000000000000000000000000000000000000000000000000000000000000003

    0    4        36          68         100          132    164           196          228           260           292       324       356      388
    0x-ID|-uint32-|-bytes3[0]-|-bytes3[1]-|-bytes(loc)-|-bool-|-uint[](loc)-|-bytes(len)-|-bytes(data)-|-uint[](len)-|-uint[0]-|-uint[1]-|-uint[2] 
         ^start of the arguments block......................................^(192th Byte location......^(256th Byte location).....
    */
    function selectorJSL(
        uint32 par1,
        bytes3[2] memory,
        bytes memory,
        bool,
        uint[] memory
    ) external pure returns (bool r) {
        r = par1 > 32 ? true : false;
    }
}

// Comments in Solidity :

// This is a single-line comment.

/// single line NatSpec comment

/**
This is a
multi-line comment.
*/
