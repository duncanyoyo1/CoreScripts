import { createServer } from 'net';

const Delimiter = '^';
const port = 4550;

const server = createServer(socket => {
    console.log('Beginning connection to tes3mp server...');

    socket.on('error', e => {
        console.log('Lost connection to tes3mp server!');
        socket.end();
    });

    socket.on('data', data => {
        const messages = parseMessage(data);
        for (const message of messages) {
            // TODO: Write handlers for message types
            console.log(message.type, message.data);
        }
    });

    // Welcome message!
    socket.write(createMessage('WELCOME', { message: 'Welcome to the webserver!' }));
});

function createMessage(key: string, data: object) {
    const stringifiedData = JSON.stringify(data);
    const joinedMessage = `${key}${Delimiter}${stringifiedData}`;
    return Buffer.from(joinedMessage);
}

function parseMessage(datum: Buffer) {
    const str = datum.toString();
    const pieces = str.split(Delimiter);
    pieces.pop(); // should be empty
    const messages = [];
    while (pieces.length > 0) {
        const type = pieces.shift();
        const strData = pieces.shift();
        let data = strData;
        try {
            data = JSON.parse(strData as string);
        } catch { }

        messages.push({ type, data });
    }
    return messages;
}

server.listen(port);
console.log(`Listening on port ${port}...`);
