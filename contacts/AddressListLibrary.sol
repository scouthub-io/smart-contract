// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library AddressListLibrary {
    using AddressListLibrary for Addresses;

    struct Addresses {
        address[] _items;
    }

    /**
     * @notice push an address to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing address type variables
     * @param element the element to add in the array
     */
    function pushAddress(Addresses storage self, address element) internal {
        if (!exists(self, element)) {
            self._items.push(element);
        }
    }

    /**
     * @notice get the address at a specific index range from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing address type variables
     */
    function getAddressesByIndexRange(
        Addresses storage self,
        uint256 start,
        uint256 end
    ) internal view returns (address[] memory) {
        require(
            start < size(self) && end <= size(self) && end - start > 0,
            "wrong index range"
        );
        uint256 totalSize = end - start;
        address[] memory _addresses = new address[](totalSize);
        for (uint256 index = 0; index < totalSize; index++) {
            _addresses[index] = self._items[index + start];
        }
        return _addresses;
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing address type variables
     */
    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing address type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Addresses storage self, address element)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing address type variables
     */
    function getAllAddresses(Addresses storage self)
        internal
        view
        returns (address[] memory)
    {
        return self._items;
    }
}
