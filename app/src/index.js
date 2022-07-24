import Web3 from "web3";
import myFlag from "../../build/contracts/Myflag.json";
const App = {
  web3: null,
  account: null,
  meta: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      // const deployedNetwork = metaCoinArtifact.networks[networkId];
      const deployedNetwork = myFlag.networks[networkId];
      this.meta = new web3.eth.Contract(
        myFlag.abi,
        deployedNetwork.address,
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];

      this.getTopics();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  getTopics: async function() {
    const { getCount } = this.meta.methods;
    // const num = await getCount(this.account).call();
    const num = await getCount().call();
    const countDiv = document.getElementById("count");
    const ol = document.getElementById("topics")
    countDiv.innerHTML = num;
    ol.innerHTML=''
    let i = 0
    for(i=0;i<num;i++){
      this.meta.topics.call(i).then((res)=>{
        // function(topic){
          // const title = topic[0];
          // const content =  topic[1];
          // const owner = topic[2];
          // const status = topic[3];
          // const ts = topic[4];
          console.log(" get res")
          const title = res[0];
          ol.innerHTML += `<li>${title} | ${content}  | ${owner} | ${status} |  ${ts}</li>`
        }
      )
    }


    // const topicElement = document.getElementsByClassName("topics")[0];
    // topicElement.innerHTML = num;
  },

  postTopic: async function() {
    const title = document.getElementById("title").value;
    const content = document.getElementById("content").value;
    const status = document.getElementById("status").value;
    const { postTopic } = this.meta.methods;
    await postTopic(title, content,status).send({ from: this.account,gas:1000000});

    this.setStatus("Transaction complete!");
    this.getCount();
  },

  setStatus: function(message) {
    const status = document.getElementById("status");
    status.innerHTML = message;
  },
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
