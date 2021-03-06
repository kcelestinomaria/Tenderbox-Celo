// Tendering and Escrow Contracts

pragma solidity >=0.4.22 <0.9.0;

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// IERC-20 contract 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For the TenderEscrow Contracts
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract TenderingSession {
  // SafeMath for safe integer operations
  using SafeMath for uint256;

  // List of all the Tenders
  Project[] private Tenders;
	
  // event for when new tender starts
  event TenderingSession(
    address contractAddress,
    address tenderOriginator,//previously Project Creator
    string tenderProposal,//previously title
    string description,
    string productName,
    string category,
    uint256 productUnitPrice,
    uint256 biddingDeadline, // previously fundraising deadline
    uint256 amountToSecure 
  );

  function startTender(
    IERC20 cUSDToken,
    string calldata tenderProposal, 
    string calldata description,
    string calldata category,
    uint durationInDays, // Will change this to durationInSeconds
    //uint amountToRaise
    uint amountToSecureTender
  ) external {
    // Will change below to duration in seconds
    uint raiseUntil = block.timestamp.add(durationInDays.mul(1 days));
    
    Tender newTender = new Tender(cUSDToken, payable(msg.sender), tenderProposal, description, category, raiseUntil, amountToSecureTender);
    tenders.push(newTender);
    
    emit TendersStarted(
      address(newTender),
      msg.sender,
      tenderProposal,
      description,
      category,
      raiseUntil,
      amountToSecureTender
    );
  }

  function returnTenders() external view returns(Tender[] memory) {
    return tenders;
  }

}


contract Tender is Ownable {
  // The tender has escrow features so that it can recieve bids and lock them until tender execution
  Escrow escrow;
  address payable vendor;//wallet
  using SafeMath for uint256;
  
  enum TenderState {
    //Fundraising,
    InBiddingSession,
    Expired,
    //Successful
    Secured
  }
  IERC20 private cUSDToken;
  
  // Initialize public variables
  //address payable public creator;
  address payable public tenderOriginator
  //uint public goalAmount;
  uint public amountToSecure;
  //uint public completeAt;
  //uint256 public currentBalance;
  //uint public raisingDeadline;
  uint public securingTenderDeadline;
  string public tenderProposal;
  string public description;
  string public category;

  // Initialize state at InBiddingSession(fundraising)
  TenderState public state = TenderState.InBiddingSession;  
	
  mapping (address => uint) public vendorSubmissions;//contributions

  // Event when vendor interest gold/dollars (funding) is received
  event ReceivedInterest(address vendor, );//will add some more here); //removed uint currentTotal and amount

  // Event for when the project creator has received their funds
  //event CreatorPaid(address recipient);

  modifier theState(TenderState _state) {
    require(state == _state);
   _;
  }

  constructor
  (
    IERC20 token,
    //address payable tenderOriginator,
    address payable _vendor
    string memory tenderProposal, 
    string memory tenderDescription,
    string memory tenderCategory,
    uint tenderSecuringDeadline,
    //uint projectGoalAmount
  ) {
    //escrow = new Escrow();
    vendor = _vendor;
    cUSDToken = token;
    issuer = tenderOriginator;//formally creator
    title = tenderProposal; 
    description = tenderDescription; 
    category = tenderCategory; 
    amountToSecure = tenderSecuringAmount;
    securingDeadline = tenderSecuringDeadline;
    //currentBalance = 0;
  }

  
  // Secure a tender
  //function sendPayment(uint256 amount) external theState(TenderState.InBiddingSession) payable {
     //cUSDToken.transferFrom(msg.sender, address(this), amount);
     //cUSDToken.escrow.deposit.value(msg.value) (vendor)
     
     // formely contribute
  function stakeInterest(uint256 amount) external theState(TenderState.InBiddingSession) payable {
    cUSDToken.transferFrom(msg.sender, address(this), amount);
    
    stakingInterests[msg.sender] = stakingInterests[msg.sender].add(amount);
    currentBalance = currentBalance.add(amount);
    emit ReceivedInterest(msg.sender, amount, currentBalance);
    
    checkIfBiddingSessionExpired();
  }

  // check Tender state
  function checkIfBiddingSessionExpired() public {
    if (block.timestamp > securingDeadline) {
      state = TenderState.Expired;
    }
  }

  //function payOut() external returns (bool result) {
    //require(msg.sender == tenderOriginator);//previously creator
    
    //uint256 totalRaised = currentBalance;
    //currentBalance =  0;
    
    //if (cUSDToken.transfer(msg.sender, totalRaised)) {
      //emit CreatorPaid(creator);
      //state = ProjectState.Successful;
      //return  true;
    //} 
    //else {
      //currentBalance = totalRaised;
      //state = ProjectState.Successful;
    //}
    
    //return  false;
  //}

  function getDetails() public  view  returns
  (
    address payable tenderOriginator,
    string memory tenderProposal,
    string memory tenderDescription,
    string memory category,
    uint securingDeadline,//previously fundRaisingDeadline,
    TenderState currentState, 
    //uint256 projectGoalAmount, 
    //uint256 currentAmount
  ) {
    projectCreator = creator;
    projectTitle = title;
    projectDescription = description;
    projectImageLink = imageLink;
    fundRaisingDeadline = raisingDeadline;
    currentState = state;
    projectGoalAmount = goalAmount;
    currentAmount = currentBalance;
  }

}





contract TenderEscrow is Ownable {
    Escrow escrow;
    address payable vendor //wallet, contributor

    constructor(address payable _vendor) public {
        escrow = new Escrow();
	vendor = _vendor
    }

    /**
     * Receives Celo Gold/Dollars from vendors who are interested on executing a tender
     */
     // The amount to be submitted is predefined and exact
    function submitBid() external payable {
        escrow.deposit.value(msg.value)(vendor);
    }

    /**
     * Withdraw funds to wallet
     */
    function withdrawBid() external onlyOwner {
        escrow.withdraw(vendor);
    }

    /**
     * Checks balance available to withdraw
     * @return the balance
     */
    function balance() external view onlyOwner returns (uint256) {
        return escrow.depositsOf(wallet);
    }
}


pragma solidity ^0.6.0;

contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    State public currState;
    
    address public buyer;
    address payable public seller;
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    
    constructor(address _buyer, address payable _seller) public {
        buyer = _buyer;
        seller = _seller;
    }
    
    function deposit() onlyBuyer external payable {
        require(currState == State.AWAITING_PAYMENT, "Already paid");
        currState = State.AWAITING_DELIVERY;
    }
}