"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GameError = exports.AuthorizationError = exports.AuthenticationError = exports.ValidationError = exports.Win5xError = void 0;
// Error Types
class Win5xError extends Error {
    constructor(message, code, statusCode = 400) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
        this.name = 'Win5xError';
    }
}
exports.Win5xError = Win5xError;
class ValidationError extends Win5xError {
    constructor(message) {
        super(message, 'VALIDATION_ERROR', 400);
    }
}
exports.ValidationError = ValidationError;
class AuthenticationError extends Win5xError {
    constructor(message = 'Authentication required') {
        super(message, 'AUTHENTICATION_ERROR', 401);
    }
}
exports.AuthenticationError = AuthenticationError;
class AuthorizationError extends Win5xError {
    constructor(message = 'Insufficient permissions') {
        super(message, 'AUTHORIZATION_ERROR', 403);
    }
}
exports.AuthorizationError = AuthorizationError;
class GameError extends Win5xError {
    constructor(message, code = 'GAME_ERROR') {
        super(message, code, 400);
    }
}
exports.GameError = GameError;
