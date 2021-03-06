// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Poll {

    address director;
    address[] shareholders;

    Question[] questions;

    struct Question {
        string name;                        // Question identifier.
        address[] voted;                    // Mapping of addresses that have voted, if true - they've voted.
        int voteCount;                      // Accumulated votes. Positive non-zero values represent accepted questions, negative values rejected ones.
        bool open;                          // Open status of question.
    }

    /** 
     * @dev Create a new Poll.
     */
    constructor() {
        
        // Simply sets the director of this Poll - grants admin privileges.
        director = msg.sender;

    }

    /**
    * @dev Checks if address in the provided array and returns corresponding index. If the 
    * address cannot be found, returns (false, 0).
    * @return success true if address found, otherwise false.
    * @return arrIndex uint index of found address. Defaults to 0.
    **/
    function inArray(address[] memory arr, address _address) internal pure returns (bool success, uint arrIndex) {

        // Only search if there is a list to search.
        if (arr.length > 0) {

            // Search for address index;
            for (uint i=0; i<arr.length; i++) {
                if (arr[i] == _address) {
                    return (true, i);
                }
            }
        }

        // Base case - address not found.
        return (false, 0);

    }

    /** 
    * @dev Adds an address to the shareholders array, it is isn't already in there.
    **/
    function addShareholder(address _shareholder) public {
        require(msg.sender == director, "Only the director can add shareholders!");

        // Only add new addresses.
        (bool inList, ) = inArray(shareholders, _shareholder);
        require(!inList, "Address already a shareholder!");

        // Update address to shareholder in mapping.
        shareholders.push(_shareholder);

    }

    /** 
    * @dev Removes an address from the shareholders array, if it exists. Cleans up the array
    * so there are no gaps.
    **/
    function removeShareholder(address _shareholder) public  {
        require(msg.sender == director, "Only the director can remove shareholders!");

        // Only remove known addresses.
        (bool inList, uint index) = inArray(shareholders, _shareholder);
        require(inList, "Address not a shareholder!"); // This also checks for an empty list!

        // Remove address from shareholder mapping by copying over last value. This stops gaps from forming.
        shareholders[index] = shareholders[shareholders.length-1];

        // Then, remove last value to delete duplicates.
        shareholders.pop();

    }

    /** 
    * @dev Adds an address to the shareholders array, it is isn't already in there.
    * @param _question string name description of the question.
    **/
    function addQuestion(string memory _question) public {
        require(msg.sender == director, "Only the director can add questions!");

        // Create question from input.
        Question memory q;
        q.name = _question;
        q.open = true;

        // Push to question array - stores in persistent storage.
        questions.push(q);

    }

    /**
    * @dev Lets a shareholder vote on a question.
    * @param _question uint index of the question to be voted on.
    * @param _decision boolean describing the actual vote of the shareholder.
    **/
    function voteOnQuestion(uint _question, bool _decision) public {
        
        // Only allow shareholders to vote.
        (bool exists, ) = inArray(shareholders, msg.sender);
        require(exists, "Address not a shareholder!");

        // Only allow shareholder to vote once.
        (bool hasVoted, ) = inArray(questions[_question].voted, msg.sender);
        require(!hasVoted, "Shareholder has already voted on this question!");

        // Only allow voting on open questions.
        require(_question < questions.length, "Selected question is out of bounds of question array.");
        require(questions[_question].open, "Question is closed, you cannot vote.");

        // Actual voting.
        if (_decision) {
            questions[_question].voteCount++;
        } else {
            questions[_question].voteCount--;
        }

        // Remember that this shareholder voted for this question.
        questions[_question].voted.push(msg.sender);

    }

    /**
    * @dev Closes a question corresponding to the given index. Only usable by director.
    * @param _question uint index of the question to be voted on.
    **/ 
    function closeQuestion (uint _question) public {
        require(msg.sender == director, "Only the director can close the vote!");

        // Only allow closing of open questions.
        require(_question < questions.length, "Selected question is out of bounds of question array.");
        require(questions[_question].open, "Question is already closed.");

        // Close vote.
        questions[_question].open = false;

    }

    /**
    * @dev Allows shareholders and the director to view results. Shareholders can only see results
    * of closed questions.
    * @param _question uint index of the question to be voted on.
    * @return result string describing the vote's result.
    **/
    function viewResultOf(uint _question) public view returns (string memory result){

        if (msg.sender != director) {

            // Only shareholders can see the results.
            (bool exists, ) = inArray(shareholders, msg.sender);
            require(exists, "You are not a shareholder and cannot see the results.");
            
            // Only allow closed questions to be viewed.
            require(!questions[_question].open, "Viewing results require the question to be closed.");
        }

        // Return the actual question object. This contains the voteCount, showing the result.
        require(_question < questions.length, "Selected question is out of bounds of question array.");
        
        // When voteCount == 0 (i.e. equal amount of yes and no).
        result = "Majority votes indecisive.";
        
        // More yes than no answers.
        if (questions[_question].voteCount > 0) {
            result = "Majority votes yes";
        }

        // More no than yes.
        if (questions[_question].voteCount < 0) {
            result = "Majority votes no";
        }
        
    }

}
