const mongoose = require('mongoose');
const { Schema } = mongoose;
 
const logSchema = new Schema({
  level: {
    type: String,
    enum: ['info', 'error', 'warn', 'debug'],
    default: 'info'
  },
  message: {
    type: String,
    required: true
  },
  studentId: {
    type: Schema.Types.ObjectId,
    ref: 'User'
  },
  studentName: {
    type: String
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
}, { collection: 'studentlogs' }); // Specify the collection name here
 
const Log = mongoose.model('Log', logSchema);
 
module.exports = Log;