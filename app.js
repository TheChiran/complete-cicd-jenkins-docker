import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import express from 'express';
import OS from 'os';
import bodyParser from 'body-parser';
import mongoose from 'mongoose';
import cors from 'cors';
import serverless from 'serverless-http';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '/')));
app.use(cors());

async function connectToDatabase() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB Connection Successful");
        return true;
    } catch (err) {
        console.error("MongoDB Connection Error:", err);
        return false;
    }
}

connectToDatabase();

const Schema = mongoose.Schema;

const dataSchema = new Schema({
    name: String,
    id: Number,
    description: String,
    image: String,
    velocity: String,
    distance: String
});

const planetModel = mongoose.model('planets', dataSchema);



app.post('/planet', function (req, res) {
    // console.log("Received Planet ID " + req.body.id)
    planetModel.findOne({ id: req.body.id })
        .then(planetData => {
            if (!planetData) { // Check if planetData is null (not found)
                res.send("Planet not found. Please select a number from 0 to 9.");
            } else {
                res.send(planetData);
            }
        })
        .catch(err => {
            console.error("Error fetching planet data:", err); // Log the error
            res.status(500).send("Error fetching planet data."); // Send an error response
        });
});

app.get('/', async (req, res) => {
    res.sendFile(path.join(__dirname, '/', 'index.html'));
});

app.get('/api-docs', (req, res) => {
    fs.readFile('oas.json', 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading file:', err);
            res.status(500).send('Error reading file');
        } else {
            res.json(JSON.parse(data));
        }
    });
});

app.get('/os', function (req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "os": OS.hostname(),
        "env": process.env.NODE_ENV
    });
});

app.get('/live', function (req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "live"
    });
});

app.get('/ready', function (req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "ready"
    });
});

app.listen(3000, () => { console.log("Server successfully running on port - " + 3000); });

export default app;

//export const handler = serverless(app);