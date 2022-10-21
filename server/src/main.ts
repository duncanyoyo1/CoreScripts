import { createServer } from 'net';
import { GreetingMessageHandler, GreetingMessageKey as ReceivingGreetingKey } from './handlers/handleGreetingMessage';
import { CreateGreetingMessageData, GreetingMessageKey as SendingGreetingKey } from './messages/welcomeMessage';

type MessageType = {
    type: string;
    data: any;
}

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
            switch (message.type) {
                case ReceivingGreetingKey: GreetingMessageHandler(message.data);
                // Add other message handlers here
                // TODO: This is not a scalable design
            }
        }
    });

    socket.write(
        createMessage(SendingGreetingKey, CreateGreetingMessageData())
    );
});

function createMessage(key: string, data: object) {
    const stringifiedData = JSON.stringify(data);
    const joinedMessage = `${key}${Delimiter}${stringifiedData}`;
    return Buffer.from(joinedMessage);
}

function parseMessage(datum: Buffer): MessageType[] {
    const str = datum.toString();
    const pieces = str.split(Delimiter);
    pieces.pop(); // should be empty
    const messages: MessageType[] = [];
    while (pieces.length > 0) {
        const type = pieces.shift();
        const strData = pieces.shift();
        if (!type || !strData) break;

        try {
            const data = JSON.parse(strData);
            messages.push({ type, data });
        } catch (e) {
            console.error('Failed to parse data!');
            console.error(e);
        }
    }
    return messages;
}

server.listen(port);
console.log(`Listening on port ${port}...`);
