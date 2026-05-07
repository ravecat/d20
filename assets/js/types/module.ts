export const MODULE_READY_MESSAGE = "module.ready";
export const MODULE_CONNECT_MESSAGE = "module.connect";

export interface ModuleBootstrap {
  moduleId: string;
  socketUrl: string;
  topic: string;
  token: string;
}

export interface ModuleEntry {
  id: string;
  title: string;
  embedUrl: string;
  allowedOrigins: string[];
  sandbox: string[];
  bootstrap?: ModuleBootstrap;
}

export interface ModuleReadyMessage {
  type: typeof MODULE_READY_MESSAGE;
  moduleId: string;
}

export type ModuleConnectMessage = ModuleBootstrap & {
  type: typeof MODULE_CONNECT_MESSAGE;
};
