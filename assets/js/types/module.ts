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
  type: "d20.module.ready";
  moduleId: string;
}
