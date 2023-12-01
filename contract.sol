//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
      function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    }
contract ppk_staking
    {
       
        address  public owner=0x4e28A7871B33C8358A5A116f62696d073BEc4670;
        address public Staking_token = 0x51a61EC45a849360580Daaa52b1a30D699D1BB32; //credit
        address public Reward_Token  = 0x51a61EC45a849360580Daaa52b1a30D699D1BB32; // bel3

 

        uint public totalusers;
        uint public Lockup_period= 369 days;
                uint public apr= 35 *10**18;

        uint public per_day_divider= 1 minutes;


        uint public totalbusiness; 
        mapping(uint=>address) public All_investors;
        mapping(address=>bool) public isUser;

        struct allInvestments{

            uint investedAmount;
            uint withdrawnTime;
            uint DepositTime;
            uint investmentNum;
            uint unstakeTime;
            bool unstake;
            uint reward;



        }



        struct Data{

            mapping(uint=>allInvestments) investment;
            uint noOfInvestment;
            uint totalInvestment;
            uint totalWithdraw_reward;
            bool investBefore;
        }


        struct time_Apy
        {
            uint timeframe;
            uint APR;
        }
  
        mapping(address=>Data) public user;

            mapping(address=>mapping(uint=>allInvestments)) public user_investments;

        constructor(){
            
  



        }

       


        function Stake(uint _investedamount,uint choose_val) external  returns(bool success)
        {
            require(_investedamount > 0,"value is not greater than 0");     //ensuring that investment amount is not less than zero

            require(Token(Staking_token).allowance(msg.sender,address(this))>=_investedamount,"allowance");

            if(user[msg.sender].investBefore == false)
            { 
                All_investors[totalusers]=msg.sender;
                isUser[msg.sender]=true;
                totalusers++;                                     
            }

            uint num = user[msg.sender].noOfInvestment;
            user[msg.sender].investment[num].investedAmount =_investedamount;
            user[msg.sender].investment[num].DepositTime=block.timestamp;
            user[msg.sender].investment[num].withdrawnTime=block.timestamp + Lockup_period ;  
            
            user[msg.sender].investment[num].investmentNum=num;


            user[msg.sender].totalInvestment+=_investedamount;
            user[msg.sender].noOfInvestment++;
            totalbusiness+=_investedamount;


            Token(Staking_token).transferFrom(msg.sender,address(this),_investedamount);
            user_investments[msg.sender][num] = user[msg.sender].investment[num];
            user[msg.sender].investBefore=true;

            return true;
            
        }

       function get_TotalReward() view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = user[msg.sender].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(!user[msg.sender].investment[i].unstake)
                {
                    if(block.timestamp < user[msg.sender].investment[i].withdrawnTime)
                    {
                        depTime =block.timestamp - user[msg.sender].investment[i].DepositTime;
                    }
                    else
                    {    
                        depTime =user[msg.sender].investment[i].withdrawnTime - user[msg.sender].investment[i].DepositTime;
                    }                
                }
                else{
                    depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;
                }
                depTime=depTime/per_day_divider; //1 day
                if(depTime>0)
                {
                     rew  =  (((user[msg.sender].investment[i].investedAmount * (apr)  )/ (100*10**18) )/369);


                    totalReward += depTime * rew;
                }
            }
            totalReward -= user[msg.sender].totalWithdraw_reward;

            return totalReward;
        }

        function getReward_perInv(uint i) view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;

                if(!user[msg.sender].investment[i].unstake)
                {
                    if(block.timestamp < user[msg.sender].investment[i].withdrawnTime)
                    {
                        if(block.timestamp < user[msg.sender].investment[i].withdrawnTime)
                        {
                            depTime =block.timestamp - user[msg.sender].investment[i].DepositTime;
                        }
                        else
                        {    
                            depTime =user[msg.sender].investment[i].withdrawnTime - user[msg.sender].investment[i].DepositTime;
                        }                        
                    }
                    else
                    {    
                        depTime =user[msg.sender].investment[i].withdrawnTime - user[msg.sender].investment[i].DepositTime;
                    }     
                }
                else
                {
                    depTime =user[msg.sender].investment[i].unstakeTime - user[msg.sender].investment[i].DepositTime;
                }
                depTime=depTime/per_day_divider; //1 day
                if(depTime>0)
                {
                     rew  =  (((user[msg.sender].investment[i].investedAmount * (apr)  )/ (100*10**18) )/369);


                    totalReward += depTime * rew;
                }
            

            return totalReward;
        }



        function withdrawReward() external returns (bool success){
            uint Total_reward = get_TotalReward();
            require(Total_reward>0,"you dont have rewards to withdrawn");         //ensuring that if the investor have rewards to withdraw
        
            Token(Reward_Token).transfer(msg.sender,Total_reward);             // transfering the reward to investor             
            user[msg.sender].totalWithdraw_reward+=Total_reward;

            return true;

        }


        function unStake(uint num) external  returns (bool success)
        {


            require(user[msg.sender].investment[num].investedAmount>0,"you dont have investment to withdrawn");             //checking that he invested any amount or not
            require(!user[msg.sender].investment[num].unstake ,"you have withdrawn");
            uint amount=user[msg.sender].investment[num].investedAmount;


            if(user[msg.sender].investment[num].withdrawnTime > block.timestamp)
            {
                uint penalty_fee=(amount*(10*10**18))/(100*10**18);
                Token(Staking_token).transfer(owner,penalty_fee);            
                amount=amount-penalty_fee;
            }
            Token(Staking_token).transfer(msg.sender,amount);             //transferring this specific investment to the investor
          
            user[msg.sender].investment[num].unstake =true;    
            user[msg.sender].investment[num].unstakeTime =block.timestamp;    

            user[msg.sender].totalInvestment-=user[msg.sender].investment[num].investedAmount;
            user_investments[msg.sender][num] = user[msg.sender].investment[num];


            return true;

        }

        function getTotalInvestment() public view returns(uint) {   //this function is to get the total investment of the ivestor
            
            return user[msg.sender].totalInvestment;

        }

        function getAll_investments() public view returns (allInvestments[] memory Invested) { //this function will return the all investments of the investor and withware date
            uint num = user[msg.sender].noOfInvestment;
            uint temp;
            uint currentIndex;
            
            for(uint i=0;i<num;i++)
            {
               if(!user[msg.sender].investment[i].unstake ){
                   temp++;
               }

            }
         
            Invested =  new allInvestments[](temp) ;

            for(uint i=0;i<num;i++)
            {
               if( !user[msg.sender].investment[i].unstake ){

                   Invested[currentIndex]=user[msg.sender].investment[(num-1)-i];
                    Invested[currentIndex].reward=getReward_perInv((num-1)-i);

                   currentIndex++;
               }

            }
            return Invested;

        }

        function getAll_investments_ForReward() public view returns (allInvestments[] memory Invested) { //this function will return the all investments of the investor and withware date
            uint num = user[msg.sender].noOfInvestment;
        
         
            Invested =  new allInvestments[](num) ;

            for(uint i=0;i<num;i++)
            {
                   Invested[i]=user[msg.sender].investment[(num-1)-i];
                    Invested[i].reward=getReward_perInv((num-1)-i);


            }
            return Invested;

        }
        
  
        function transferOwnership(address _owner)  public
        {
            require(msg.sender==owner,"only Owner can call this function");
            owner = _owner;
        }

        function total_withdraw_reaward() view public returns(uint){


            uint Temp = user[msg.sender].totalWithdraw_reward;

            return Temp;
            

        }
        function get_currTime() public view returns(uint)
        {
            return block.timestamp;
        }
        
        function get_withdrawnTime(uint num) public view returns(uint)
        {
            return user[msg.sender].investment[num].withdrawnTime;
        }



       function withdrawFunds(uint token,uint _amount)  public
        {
            require(msg.sender==owner);
            address curr_add;

            if(token==1){
                curr_add= Staking_token;
            }else if(token==2)
            {
                curr_add= Reward_Token;
            }
            uint bal = Token(curr_add).balanceOf(address(this));
            require(bal>=_amount);

            Token(curr_add).transfer(curr_add,_amount); 
        }



    } 