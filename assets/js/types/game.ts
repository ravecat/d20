export interface GameMetadata {
  name: string | null;
  alternateNames: string[];
  categories: string[];
  mechanics: string[];
  description?: string | null;
  thumbnailUrl?: string | null;
  imageUrl?: string | null;
  yearPublished?: number | null;
  minPlayers?: number | null;
  maxPlayers?: number | null;
  playingTime?: number | null;
  minPlayTime?: number | null;
  maxPlayTime?: number | null;
  minAge?: number | null;
  complexity?: number | null;
  rating?: number | null;
}

export interface GameCatalogEntry {
  slug: string;
  status: GameStatus | null;
  game: GameMetadata;
}

export type GameStatus = "active" | "in_progress";

export interface AttrConfig {
  id: string;
  name: string;
  type: string;
  label?: string;
  position?: number;
  value?: string | number | boolean | null;
  required?: boolean;
  values?: string[];
  errors?: string[];
}

export type Attrs = Record<string, AttrConfig>;

export interface SessionMember {
  status: "online" | "offline";
  online_at?: number;
  display_name?: string;
  avatar?: string | null;
}

export interface SessionPermissions {
  can_start_game?: boolean;
  [permission: string]: boolean | undefined;
}

export interface Session<TGame = unknown> {
  id: string;
  phase: "waiting_for_players" | "in_progress" | "finished";
  owner_id: string;
  members: Record<string, SessionMember>;
  permissions?: SessionPermissions;
  attrs?: Attrs;
  game: TGame;
}
