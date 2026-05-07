import { Socket } from "phoenix";

const socket = new Socket("/socket", { authToken: window.actorToken });
socket.connect();

export default socket;
