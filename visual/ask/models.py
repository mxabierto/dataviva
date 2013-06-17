import re
from unicodedata import normalize
from sqlalchemy import and_
from sqlalchemy.dialects import mysql
from visual import db, app
from visual.utils import AutoSerialize

from visual.account.models import User
from visual.attrs import models as attr_models

import flask.ext.whooshalchemy as whooshalchemy

TYPE_QUESTION = 0
TYPE_REPLY = 1

question_tags = db.Table('ask_question_tags',
    db.Column('tag_id', db.Integer, db.ForeignKey('ask_tag.id')),
    db.Column('question_id', db.Integer, db.ForeignKey('ask_question.id'))
)


class Vote(db.Model):

    __tablename__ = 'ask_vote'
    type = db.Column(db.SmallInteger, primary_key = True, default=TYPE_QUESTION)
    type_id = db.Column(db.Integer, primary_key = True)
    user_id = db.Column(db.Integer, db.ForeignKey(User.id), primary_key = True)

    def __repr__(self):
        return '<Vote %r:%r by:%r>' % (self.type, self.type_id, self.user_id)

class Question(db.Model, AutoSerialize):

    __tablename__ = 'ask_question'
    __searchable__ = ['question', 'body', 'status_notes']
    id = db.Column(db.Integer, primary_key = True)
    user_id = db.Column(db.Integer, db.ForeignKey(User.id))
    question = db.Column(db.String(140))
    slug = db.Column(db.String(140))
    app = db.Column(db.String(60))
    body = db.Column(db.Text())
    timestamp = db.Column(db.DateTime)
    status_id = db.Column(db.Integer, db.ForeignKey('ask_status.id'), default = 1)
    status_notes = db.Column(db.Text())
    tags = db.relationship('Tag', secondary=question_tags,
            backref=db.backref('question', lazy='dynamic'))            
    replies = db.relationship("Reply", backref = 'question', lazy = 'dynamic', order_by="Reply.parent_id")
    votes = db.relationship("Vote",
            primaryjoin= "and_(Question.id==Vote.type_id, Vote.type=={0})".format(TYPE_QUESTION),
            foreign_keys=[Vote.type_id], backref = 'question', lazy = 'dynamic')
    
    @staticmethod
    def make_unique_slug(question):
        """Generates an slightly worse ASCII-only slug."""
        _punct_re = re.compile(r'[\t !"#$%&\'()*\-/<=>?@\[\\\]^_`{|},.]+')
        delim = "_"
        result = []
        for word in _punct_re.split(question.lower()):
            word = normalize('NFKD', word).encode('ascii', 'ignore')
            if word:
                result.append(word)
        slug = unicode(delim.join(result))        
        """Check if slug is unique otherwise append the last inserted ID +1"""
        if Question.query.filter_by(slug = slug).first() is not None:
            last_q = Question.query.order_by(Question.id.desc()).first()
            slug = str(last_q.id) + delim + slug
        return slug
    
    def _find_or_create_tag(self, attr_type, attr_id):
        t = Tag.query.filter_by(attr_type=attr_type, attr_id=attr_id).first()
        if not(t):
            t = Tag(attr_type=attr_type, attr_id=attr_id)
        return t
    
    def str_tags(self, tag_list):
        # clear the list first
        while self.tags:
            del self.tags[0]
        # next add the new tags
        for tag in tag_list:
            attr_type, attr_id = tag.split(":")
            self.tags.append(self._find_or_create_tag(attr_type, attr_id))
    
    def __repr__(self):
        return '<Question %r>' % (self.question)

class Tag(db.Model):

    __tablename__ = 'ask_tag'
    id = db.Column(db.Integer, primary_key=True)
    attr_type = db.Column(db.String(20))
    attr_id = db.Column(db.String(12))
    
    def __repr__(self):
        return '<%r: %r>' % (self.attr_type, self.attr_id)
    
    def to_attr(self):
        attr = getattr(attr_models, self.attr_type.title())
        attr = attr.query.get(self.attr_id)
        return attr

class Status(db.Model):

    __tablename__ = 'ask_status'
    id = db.Column(db.Integer, primary_key = True)
    name = db.Column(db.String(255))
    questions = db.relationship(Question, backref = 'status', lazy = 'dynamic')

    def __repr__(self):
        return '<Status %r>' % (self.name)

    def __unicode__(self):
        return '%s' % (self.name)

class Reply(db.Model):

    __tablename__ = 'ask_reply'
    id = db.Column(db.Integer, primary_key = True)
    parent_id = db.Column(db.Integer)
    body = db.Column(db.Text())
    timestamp = db.Column(db.DateTime)
    user_id = db.Column(db.Integer, db.ForeignKey(User.id))
    question_id = db.Column(db.Integer, db.ForeignKey(Question.id))
    votes = db.relationship("Vote",
            primaryjoin= "and_(Reply.id==Vote.type_id, Vote.type=={0})".format(TYPE_REPLY),
            foreign_keys=[Vote.type_id], backref = 'reply', lazy = 'dynamic')
    flags = db.relationship("Flag", backref = 'reply', lazy = 'dynamic')
    
    def __repr__(self):
        return '<Reply %r>' % (self.id)

class Flag(db.Model):

    __tablename__ = 'ask_reply_flag'
    reply_id = db.Column(db.Integer, db.ForeignKey(Reply.id), primary_key = True)
    user_id = db.Column(db.Integer, db.ForeignKey(User.id), primary_key = True)

    def __repr__(self):
        return '<Flag %r by user:%r>' % (self.reply_id, self.user_id)

# For full text search support
whooshalchemy.whoosh_index(app, Question)