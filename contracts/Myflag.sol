// SPDX-License-Identifier: MIT
// pragma solidity >=0.4.21 <0.7.0;
//    pragma solidity ^0.8.0;
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Myflag is ERC20,VRFConsumerBaseV2{
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;


//   address address_VRFadmin = 0x7251caa9450d2c536426fbdfc1edbeafbc19f26e;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  // Storage parameters
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;

    address Boss;
    // uint8 rewardNum = 1;

    uint topic_id;
    mapping (uint => Topic) allTopic;
    mapping (address => uint) balances;
    mapping (address => uint) public authLevel;
    mapping (address => uint[]) public listedTopics;
    mapping (address => uint) modifyCount;
    mapping (address => Topic[]) public commitedTopics;
    mapping (uint => uint)  checkCount;
    mapping (uint =>address[]) checkerRecorder;
    mapping (uint =>bool[]) checkStatusRecorder;
    mapping(address=>bool) gamerStatusRecord;

    // mapping(uint=>Topic)[] myTopics_with_id;
    uint public gamer_id;
    Topic[] public myTopics;
    address[]  gamers;
    // mapping (uint => address) gamers;
    //
    struct Topic{
        // uint id;
        string title;
        string content;
        address owner;
        bool status;
        bool commited;
        // bool First_status;
        // // bool doubleChecked;
        bool isvalid;
        uint ts;
        // uint deadline;
        // bool exceed;
        // uint hardlevel;
    }
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    // event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //
    constructor()  ERC20("FlagToken","FLAG") VRFConsumerBaseV2(vrfCoordinator) {
        Boss = msg.sender;
        s_owner = msg.sender;
        _mint(msg.sender,100000);
        balances[msg.sender] = 10000;
        //1 管理员 2 用户
        authLevel[msg.sender] = 1;
        // //先填充一个管理员 使只有第一个gamer的时候，gamers.length>1
        // gamer_id = 1;
        // gamers.push(msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        //Create a new subscription when you deploy the contract.
        createNewSubscription();
        // addConsumer(address(this));
    }

    modifier byBoss{
        require(msg.sender == Boss,"not Boss!");
        _;
    }
    modifier byAdmin(uint _authCode){
        require(authLevel[msg.sender] <= _authCode,"not enough auth!");
        _;
    }
    modifier byOwner(uint id){
        require(msg.sender == allTopic[id].owner,"not owner!");
        _;
    }
    modifier lessThanThree{
        require(modifyCount[msg.sender]<=2,"too many times modify,please insist your last modify");
        _;
    }
    modifier notCommited(uint id){
        require(allTopic[id].commited == false,"your featured topic has been commited,please wait the DAO to confirm!");
        _;
    }
    modifier isValidContent(uint id){
      require(bytes(allTopic[id].content).length > 0,"invalid content!");
        _;
    }
    modifier isEnoughGamers{
        require(gamers.length>6,"not enough gamers...");
        _;
    }
    //
    // function getBalanceOfContract()public view returns(uint){
    //         return address(this).balance;
    // }

    //个人topic总数
    function getPersonalCount() public  view returns(uint num){
       return listedTopics[msg.sender].length;

    }
    //增加
    function postTopic(string memory _title, string memory _content,bool _status) public {
        //  topic_index => topic_id
        topic_id++;
        allTopic[topic_id] = Topic({
            title:_title,
            content:_content,
            owner:msg.sender,
            status:_status,
            commited:false,
            isvalid:false,
            ts:block.timestamp
            });
        listedTopics[msg.sender].push(topic_id);
    }
    //删除
    function deleteTopic(uint id) public{
        delete allTopic[id];
        delete listedTopics[msg.sender][id-1];
    }
    //改
    function modifyTopic(
        uint id,
        string memory _title,
        string memory _content,
        bool _status
        )public byOwner(id) notCommited(id) lessThanThree returns(bool){
            // title:_title,
            // content:_content,
            // owner:msg.sender,
            // status:_status,
            // ts:block.timestamp
            allTopic[id] = Topic({
            title:_title,
            content:_content,
            owner:msg.sender,
            status:_status,
            commited:false,
            isvalid:false,
            ts:block.timestamp
            });
          modifyCount[msg.sender]++;
          return true;
    }
    //查
    function queryTopic(string memory _title) public view returns(Topic memory _topic){
        for (uint _index = 0; _index < listedTopics[msg.sender].length; _index++) {
            uint  id = listedTopics[msg.sender][_index];
            bytes memory aa = bytes(allTopic[id].title);
            bytes memory bb = bytes(_title);
            if(comparestr(aa, bb)){
                return allTopic[id];
            }
        }
    }
    //查自己发布的全部topic
    function getMyTopics() public  returns(Topic[] memory,uint[] memory){
        for (uint _index = 0; _index < listedTopics[msg.sender].length; _index++) {
            uint  id = listedTopics[msg.sender][_index];
           myTopics.push(allTopic[id]);
          }
      return (myTopics,listedTopics[msg.sender]);
    }
    // //Owner修改状态
    // function setStatus(uint id,bool _status) public  byOwner notCommited(id) returns(bool){
    //    listedTopics[msg.sender][_index-1].status = _status;
    //    return true;
    // }
    function isGamer()internal view returns(bool){
        for(uint i = 1;i<gamers.length;i++){
            if(gamers[i]==msg.sender){
                return true;
            }
        }
        return false;
    }

    function buyTicket()public returns(bool){
        //转给Boss 用来抵扣commit获取随机数的成本
        transfer(address(Boss),1);
        // LINKTOKEN.transfer(address_VRFadmin,10);
       if(isGamer()){
            gamerStatusRecord[msg.sender]=true;
            return true;
       }
        gamer_id++;
        gamers.push(msg.sender);
        gamerStatusRecord[msg.sender]=true;
       return true;
    }
    function requestNum()public {
        requestRandomWords();
    }
    //参与奖励游戏 提交已完成Topic
    function commitTopic(uint id)public byOwner(id) notCommited(id) isValidContent(id) isEnoughGamers returns(bool){
        //提交的必须是true状态的topic
        require(allTopic[id].status == true,"invalid topic status...");
        //买过票
        require(isGamer(),"please buy ticket first...");
        require(gamerStatusRecord[msg.sender]==true,"ticket has expired,please buy again");
        //之前提交过的不能再次提交（必须新建一个topic重新提交）
        require(allTopic[id].commited ==false,"this topic has been commited,please commit a new one");
          //取随机数，指定下一个核验人
          address  checkAddress;
         do{
            requestRandomWords();
             checkAddress =  gamers[s_randomWords[s_randomWords.length-1]];
         }while(checkAddress==msg.sender||checkAddress==address(Boss));
        allTopic[id].commited = true;
        commitedTopics[checkAddress].push(allTopic[id]);
        checkerRecorder[id].push(checkAddress);
        return true;
    }
    //获取验证结果函数
    function Check(uint id,bool _status) public returns(bool){
        // //两次验证结果一致。给验证者劳动费
        // if(checkCount[id]%2==1&&
        // _status==checkStatusRecorder[id][checkCount[id]-1]){
                //  transfer(msg.sender,1);
        // }
        //两次验证结果不一致 交给管理员验证
        if(checkCount[id]%2==1&&_status!=checkStatusRecorder[id][checkCount[id]-1]){
            commitedTopics[address(Boss)].push(allTopic[id]);
            checkerRecorder[id].push(address(Boss));
            checkCount[id]++;
            checkStatusRecorder[id].push(_status);
            return true;
        }
        //两次验证结果一致。均为true，验证通过，给flag完成者奖金
        if(checkCount[id]%2==1&&_status==true&&
        _status==checkStatusRecorder[id][checkCount[id]-1]){
            allTopic[id].isvalid = true;
            transfer(allTopic[id].owner,2);
            checkCount[id]++;
            checkStatusRecorder[id].push(_status);
            //给验证者劳动费
             transfer(msg.sender,1);
             //此次参与结束，需重新购票
             gamerStatusRecord[msg.sender]==false;
            return true;
        }
        //两次验证结果一致。均为false，验证不通过
         if(checkCount[id]%2==1&&_status==false&&
        _status==checkStatusRecorder[id][checkCount[id]-1]){
            allTopic[id].isvalid = false;
            // transferFrom(allTopic[id].owner,Boss,2);
            checkCount[id]++;
            checkStatusRecorder[id].push(_status);
            //给验证者劳动费
            transfer(msg.sender,1);
             //此次参与结束，需重新购票
             gamerStatusRecord[msg.sender]==false;
            return true;
        }

        //惩罚不合格验证者
        if(msg.sender==address(Boss)){
            if(_status==true){
                if(checkStatusRecorder[id][checkCount[id]-1]==true){
                       transferFrom(checkerRecorder[id][checkCount[id]-2],checkerRecorder[id][checkCount[id]-1],1);
                }
                if(checkStatusRecorder[id][checkCount[id]-1]==false){
                       transferFrom(checkerRecorder[id][checkCount[id]-1],checkerRecorder[id][checkCount[id]-2],1);
                }
                allTopic[id].isvalid = true;
                //给通过验证的玩家奖励
                transfer(allTopic[id].owner,2);
            }else{
                 if(checkStatusRecorder[id][checkCount[id]-1]==false){
                       transferFrom(checkerRecorder[id][checkCount[id]-2],checkerRecorder[id][checkCount[id]-1],1);
                }
                if(checkStatusRecorder[id][checkCount[id]-1]==true){
                       transferFrom(checkerRecorder[id][checkCount[id]-1],checkerRecorder[id][checkCount[id]-2],1);
                }
                allTopic[id].isvalid = false;
                // transfer(allTopic[id].owner,2);
            }
                checkCount[id]++;
                checkStatusRecorder[id].push(_status);
             //此次参与结束，需重新购票
             gamerStatusRecord[msg.sender]==false;
            return true;
        }

        //取随机数，指定下一个核验人
         address  checkAddress;
         do{
            requestRandomWords();
             checkAddress =  gamers[s_randomWords[s_randomWords.length-1]];
         }while(checkAddress==msg.sender||checkAddress==address(Boss)||checkAddress==allTopic[id].owner);

         commitedTopics[checkAddress].push(allTopic[id]);
         checkerRecorder[id].push(checkAddress);
         checkCount[id]++;
         checkStatusRecorder[id].push(_status);
         return true;

    }

    function comparestr(bytes memory aa,bytes memory bb)public  pure  returns(bool){
            if(aa.length != bb.length){
                return false;
            }else{
                return keccak256(aa)==keccak256(bb);
            }
    }



    /////
    function mint(address account, uint256 amount) public  {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        // _afterTokenTransfer(address(0), account, amount);
    }

    //----- VRF main funcs -----
    // Assumes the subscription is funded sufficiently.
  function requestRandomWords() private {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint256[] memory numarray = randomWords;
    uint a = numarray[0] % gamer_id;
    s_randomWords.push(a);
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
    // Add this contract as a consumer of its own subscription.
    COORDINATOR.addConsumer(s_subscriptionId, address(this));
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription(uint256 amount) external onlyOwner {
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    //   function addConsumer(address consumerAddress) private onlyOwner {
    // Add a consumer contract to the subscription.
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    LINKTOKEN.transfer(to, amount);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

}
