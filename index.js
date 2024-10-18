const express = require('express');
const Web3 = require('web3');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'));

const contractABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'build/contracts/Marketplace.json'), 'utf8')).abi;
const contractAddress = '0x388344E6c8a9fFfd3BE48CF5CDC825d73a45C118';

const contract = new web3.eth.Contract(contractABI, contractAddress);

app.get('/resource/:id', async (req, res) => {
    try {
        const resourceId = req.params.id;
        const resource = await contract.methods.getResource(resourceId).call();
        res.json(resource);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});

app.post('/rent/:id', async (req, res) => {
    try {
        const resourceId = req.params.id;
        const { fromAddress, value } = req.body;
        
        const transaction = await contract.methods.rentResource(resourceId).send({
            from: fromAddress,
            value: web3.utils.toWei(value, 'ether')
        });
        
        res.json(transaction);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});

app.get('/resources', async (req, res) => {
    try {
        const resourceIds = await contract.methods.getResourceIds().call();
        res.json(resourceIds);
    } catch (error) {
        res.status(500).send(error.toString());
    }
});

app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});

