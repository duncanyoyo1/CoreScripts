type GreetingMessage = {
    message: string;
};

export const GreetingMessageKey = 'GREETING'

export const GreetingMessageHandler = (data: GreetingMessage) => {
    console.log('Someone sent us some love!');
    console.log(`Message: ${data.message}`);
};
