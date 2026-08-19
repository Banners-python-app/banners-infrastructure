variable "repository_name" {
    description = "Repo name"
    type = string
}

variable "tags" {
    description = "This is tags"
    type = map(string)
    default = {}
}