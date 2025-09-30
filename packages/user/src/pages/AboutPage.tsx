import React from 'react';

const AboutPage: React.FC = () => {
  return (
    <div className="p-6 max-w-3xl mx-auto">
      <div className="card">
        <div className="card-header">
          <h3 className="card-title">About Us</h3>
          <p className="card-description">Know more about Win5x</p>
        </div>
        <div className="card-content">
          <p className="text-gray-300">Win5x is a demo roulette game platform for learning and testing.</p>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;


