export interface GameMetadata {
  externalId?: number;
  slug: string;
  name: string;
  alternateNames: string[];
  description: string;
  thumbnailUrl?: string | null;
  imageUrl?: string | null;
  yearPublished?: number | null;
  minPlayers?: number | null;
  maxPlayers?: number | null;
  playingTime?: number | null;
  minPlayTime?: number | null;
  maxPlayTime?: number | null;
  minAge?: number | null;
}

export type SessionMemberStatus = "online" | "offline";

export interface GameSession<TGame = unknown> {
  id: string;
  phase: string;
  owner_id: string;
  members: Record<string, SessionMemberStatus>;
  game: TGame;
}
