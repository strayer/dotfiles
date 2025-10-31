from typing import Literal, TypedDict

Provider = Literal["vertex", "bedrock"]
VertexAuth = Literal["litellm", "direct"]
BedrockAuth = Literal["api_key", "aws_profile"]


class VertexLiteLLM(TypedDict):
    project_id: str
    base_url: str


class VertexDirect(TypedDict):
    project_id: str


class BedrockApiKey(TypedDict):
    aws_region: str


class BedrockAwsProfile(TypedDict):
    aws_region: str
    aws_profile: str


class AuthConfig(TypedDict):
    env: dict[str, str]
    api_key_helper: str | None


class ProviderConfig(TypedDict):
    common_env: dict[str, str]
    auth: dict[str, AuthConfig]


class VertexCache(TypedDict, total=False):
    litellm: VertexLiteLLM
    direct: VertexDirect


class BedrockCache(TypedDict, total=False):
    api_key: BedrockApiKey
    aws_profile: BedrockAwsProfile


class Cache(TypedDict, total=False):
    vertex: VertexCache
    bedrock: BedrockCache
