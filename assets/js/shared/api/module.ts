export interface ModuleConnection {
  endpoint: string;
  topic: string;
  token: string;
}

export interface ModuleEntry {
  embed_url: string;
  allowed_origins: string[];
  sandbox: string[];
}
