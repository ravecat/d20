import { Socket } from "phoenix";

const socket = new Socket("/socket", { authToken: window.userToken });
socket.connect();

export default socket;
