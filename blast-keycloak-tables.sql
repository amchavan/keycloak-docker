/*
 * This script wipes out all Keycloak database tables -- use with care.
 * Depending on (as of yet) unknown factors, some of the following tables may not exist (yet).

 * amchavan, 27-Oct-2020
 */

drop table web_origins;
drop table username_login_failure;
drop table user_session_note;
drop table user_role_mapping;
drop table user_required_action;
drop table user_group_membership;
drop table user_federation_mapper_config;
drop table user_federation_mapper;
drop table user_federation_config;
drop table user_consent_client_scope;
drop table user_consent;
drop table user_attribute;
drop table scope_policy;
drop table scope_mapping;
drop table user_federation_provider;
drop table resource_uris;
drop table resource_server_perm_ticket;
drop table resource_scope;
drop table resource_policy;
drop table resource_attribute;
drop table resource_server_scope;
drop table resource_server_resource;
drop table required_action_provider;
drop table required_action_config;
drop table redirect_uris;
drop table realm_supported_locales;
drop table realm_smtp_config;
drop table realm_required_credential;
drop table realm_events_listeners;
drop table realm_enabled_event_types;
drop table realm_default_roles;
drop table realm_default_groups;
drop table realm_attribute;
drop table protocol_mapper_config;
drop table protocol_mapper;
drop table policy_config;
drop table offline_user_session;
drop table offline_client_session;
drop table migration_model;
drop table idp_mapper_config;
drop table identity_provider_mapper;
drop table identity_provider_config;
drop table identity_provider;
drop table group_role_mapping;
drop table group_attribute;
drop table federated_user;
drop table federated_identity;
drop table fed_user_role_mapping;
drop table fed_user_required_action;
drop table fed_user_group_membership;
drop table fed_user_credential;
drop table fed_user_consent_cl_scope;
drop table fed_user_consent;
drop table fed_user_attribute;
drop table event_entity;
drop table keycloak_group;
drop table default_client_scope;
drop table databasechangeloglock;
drop table databasechangelog;
drop table credential;
drop table composite_role;
drop table component_config;
drop table component;
drop table client_user_session_note;
drop table client_session_role;
drop table client_session_prot_mapper;
drop table client_session_note;
drop table client_session_auth_status;
drop table client_session;
drop table client_scope_role_mapping;
drop table client_scope_client;
drop table client_scope_attributes;
drop table client_scope;
drop table client_node_registrations;
drop table client_initial_access;
drop table client_default_roles;
drop table client_auth_flow_bindings;
drop table client_attributes;
drop table client;
drop table broker_link;
drop table authenticator_config_entry;
drop table authenticator_config;
drop table authentication_execution;
drop table associated_policy;
drop table admin_event_entity;
drop table authentication_flow;
drop table user_entity;
drop table resource_server_policy;
drop table resource_server;
drop table role_attribute;
drop table keycloak_role;
drop table realm;
drop table user_session;