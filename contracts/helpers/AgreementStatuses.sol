pragma solidity 0.5.11;

/**
 * @title Contracts with statuses, types, states
 */
contract AgreementStatuses {
    enum Statuses {
        All, // for status-insensitive search
        Pending,
        Open,
        Active,
        Closed
    }
    enum ActiveStates {
        Risky,
        UnsafeBuffer
    }
    enum ClosedTypes {
        Ended,
        Liquidated,
        Blocked,
        Cancelled
    }
}